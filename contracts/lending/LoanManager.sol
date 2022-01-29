//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

contract CheddaLoanManager is Ownable, IERC165, IERC721Receiver {
    event LoanRequested(
        address indexed by,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 amount
    );
    event RequestCancelled(address indexed by, uint256 indexed requestId);
    event LoanOpened(
        address indexed openedByLender,
        address indexed borrower,
        uint256 amount
    );
    event LoanRepaid(
        address indexed repaidByBorrower,
        address indexed lender,
        uint256 repaymentAmount
    );
    event LoanForeclosed(address indexed by, address indexed foreclosedOn);

    enum LoanState {
        all,
        open,
        repayed,
        foreclosed
    }

    struct Loan {
        uint256 loanID;
        address nftContract;
        uint256 tokenID;
        uint256 principal;
        uint256 repaymentAmount;
        uint256 openedAt;
        uint256 expiresAt;
        uint256 closedAt;
        uint32 interestRate;
        LoanState state;
        address payable lender;
        address payable borrower;
    }

    enum RequestState {
        all,
        open,
        cancelled,
        accepted
    }

    struct LoanRequest {
        uint256 requestID;
        address nftContract;
        uint256 tokenID;
        uint256 amount;
        uint256 loanLength;
        address borrower;
        RequestState state;
    }

    using Counters for Counters.Counter;
    Counters.Counter internal requestCounter;
    Counters.Counter internal loanCounter;
    address public tokenAddress;

    // Interest rate to 2 basis points.
    // 1% = 100, 100% = 10000
    uint32 public interestRate = 5000;

    // Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    bytes4 internal constant ERC721_RECEIVED = 0xf0b9e5ba;

    bytes4 internal constant IS_ERC721 = 0x150b7a02;

    LoanRequest[] public requests;
    Loan[] public loans;

    constructor(address token) {
        tokenAddress = token;
    }

    modifier canTransferTokens(
        address token,
        uint256 tokenAmount,
        address fromAddress
    ) {
        IERC20 loanCurrency = IERC20(token);
        uint256 allowance = loanCurrency.allowance(fromAddress, address(this));
        require(allowance >= tokenAmount, "Loan: Amount not allowed");
        _;
    }

    modifier isApprovedFor(address nftContract, uint256 tokenID) {
        IERC721 nft = IERC721(nftContract);
        require(
            nft.getApproved(tokenID) == address(this),
            "Loan: Not approved"
        );
        _;
    }

    /// @notice Caller is requesting a loan, putting up his NFT.
    /// @dev Explain to a developer any extra details
    /// @param nftContract NFT contract address
    /// @param tokenId token ID
    /// @param amountRequested amount of loan in wei
    /// @param duration The length of the loan. Can be repayed at any point before expiry, without
    /// the risk of foreclosure.
    function requestLoan(
        address nftContract,
        uint256 tokenId,
        uint256 amountRequested,
        uint256 duration
    ) public isApprovedFor(nftContract, tokenId) {
        require(nftContract != address(0), "Loan: Invalid address");
        // todo: duration must be multiple of 1 day
        require(duration > 0 && duration <= 90 days, "Loan: Invalid duration");

        // require(duration > 0 && duration <= 90 days && duration % 1 days == 0,
        // "Loan: Invalid duration");

        require(amountRequested > 0, "Loan: Invalid loan amount");
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == _msgSender(), "Loan: Not owner");
        require(
            nft.getApproved(tokenId) == address(this),
            "Loan: Must approve"
        );

        LoanRequest memory request = LoanRequest({
            requestID: requestCounter.current(),
            nftContract: nftContract,
            tokenID: tokenId,
            amount: amountRequested,
            loanLength: duration,
            borrower: _msgSender(),
            state: RequestState.open
        });
        requestCounter.increment();
        requests.push(request);

        emit LoanRequested(_msgSender(), nftContract, tokenId, amountRequested);
    }

    /// @dev Cancels a request for a loan
    /// @param requestId ID of request to cancel
    /// Can only be called by the address that created the request
    function cancelRequest(uint256 requestId) public {
        LoanRequest storage request = requests[requestId];
        require(request.borrower == _msgSender(), "Loan: Not allowed");
        require(request.state == RequestState.open, "Loan: Invalid state");
        request.state = RequestState.cancelled;

        emit RequestCancelled(_msgSender(), requestId);
    }

    function getMyRequests(RequestState state)
        public
        view
        returns (LoanRequest[] memory)
    {
        uint256 numberOfRequests = 0;
        for (uint256 i = 0; i < requests.length; i++) {
            LoanRequest storage request = requests[i];
            if (request.borrower == _msgSender()) {
                if (state == RequestState.all) {
                    numberOfRequests++;
                } else if (state == request.state) {
                    numberOfRequests++;
                }
            }
        }
        LoanRequest[] memory myRequests = new LoanRequest[](numberOfRequests);
        uint256 j = 0;
        for (uint256 i = 0; i < requests.length; i++) {
            LoanRequest storage request = requests[i];
            if (request.borrower == _msgSender()) {
                if (state == RequestState.all) {
                    myRequests[j++] = requests[i];
                } else if (state == request.state) {
                    myRequests[j++] = requests[i];
                }
            }
        }
        return myRequests;
    }

    /// @dev Called to open a new loan. The caller of this is the lender
    /// @param requestID ID of loan request
    function openLoan(uint256 requestID) public {
        LoanRequest storage request = requests[requestID];
        require(request.state == RequestState.open, "Loan: Not open");
        IERC20 loanCurrency = IERC20(tokenAddress);
        IERC721 nft = IERC721(request.nftContract);
        address payable lender = payable(_msgSender());
        address payable borrower = payable(request.borrower);

        require(
            loanCurrency.balanceOf(lender) >= request.amount,
            "Loan: Insufficient balance"
        );
        uint256 allowance = loanCurrency.allowance(lender, address(this));
        require(allowance >= request.amount, "Loan: Not approved");
        address approvedAddress = nft.getApproved(request.tokenID);
        require(approvedAddress == address(this), "Loan: NFT not approved");

        uint256 repaymentAmount = calculateRepaymentAmount(
            request.amount,
            request.loanLength
        );
        Loan memory loan = Loan({
            loanID: loanCounter.current(),
            nftContract: request.nftContract,
            tokenID: request.tokenID,
            principal: request.amount,
            repaymentAmount: repaymentAmount,
            openedAt: block.timestamp,
            expiresAt: block.timestamp + request.loanLength,
            closedAt: 0,
            interestRate: interestRate,
            state: LoanState.open,
            lender: lender,
            borrower: borrower
        });
        loanCurrency.transferFrom(
            _msgSender(),
            borrower,
            request.amount
        );
        nft.safeTransferFrom(borrower, address(this), request.tokenID);
        loans.push(loan);
        loanCounter.increment();

        emit LoanOpened(_msgSender(), borrower, request.amount);
    }

    /// @dev Repays an open loan. Requires prior approval of token transfer for the loan repayment amount.
    /// This can only be called by the borrower.
    /// @param loanID the id of loan to repay
    function repay(uint256 loanID) public {
        Loan storage loan = loans[loanID];
        IERC20 loanCurrency = IERC20(tokenAddress);
        IERC721 nft = IERC721(loan.nftContract);
        require(_msgSender() == loan.borrower, "Loan: Can not repay");
        require(
            loanCurrency.allowance(loan.borrower, address(this)) >=
                loan.repaymentAmount,
            "Loan: Not allowed"
        );

        loanCurrency.transferFrom(
            loan.borrower,
            loan.lender,
            loan.repaymentAmount
        );
        nft.safeTransferFrom(address(this), loan.borrower, loan.tokenID);
        loan.state = LoanState.repayed;

        emit LoanRepaid(_msgSender(), loan.lender, loan.repaymentAmount);
    }

    /// @dev Forecloses on an open loan. Can only be called after loan expiry by the lender.
    /// Transfers the NFT collateral from the smart contract to the lender.
    /// @param loanID the id of loan to foreclose.
    function foreclose(uint256 loanID) public {
        Loan storage loan = loans[loanID];
        require(
            loan.state == LoanState.open && loan.expiresAt < block.timestamp,
            "Loan: Invalid state"
        );
        require(_msgSender() == loan.lender, "Loan: Not lender");

        IERC721 nft = IERC721(loan.nftContract);
        nft.safeTransferFrom(address(this), loan.lender, loan.tokenID);
        loan.state = LoanState.foreclosed;

        emit LoanForeclosed(_msgSender(), loan.borrower);
    }

    function getMyLoansAsBorrower(LoanState state)
        public
        view
        returns (Loan[] memory)
    {
        uint256 numberOfLoans = 0;
        for (uint256 i = 0; i < loans.length; i++) {
            Loan memory loan = loans[i];
            if (loan.borrower == _msgSender()) {
                if (state == LoanState.all) {
                    numberOfLoans++;
                } else if (state == loan.state) {
                    numberOfLoans++;
                }
            }
        }
        Loan[] memory myLoans = new Loan[](numberOfLoans);
        uint256 j = 0;
        for (uint256 i = 0; i < loans.length; i++) {
            Loan memory loan = loans[i];
            if (loan.borrower == _msgSender()) {
                if (state == LoanState.all) {
                    myLoans[j++] = loan;
                } else if (state == loan.state) {
                    myLoans[j++] = loan;
                }
            }
        }
        return myLoans;
    }

    function getMyLoansAsLender(LoanState state)
        public
        view
        returns (Loan[] memory)
    {
        uint256 numberOfLoans = 0;
        for (uint256 i = 0; i < loans.length; i++) {
            Loan memory loan = loans[i];
            if (loan.lender == _msgSender()) {
                if (state == LoanState.all) {
                    numberOfLoans++;
                } else if (state == loan.state) {
                    numberOfLoans++;
                }
            }
        }
        Loan[] memory myLoans = new Loan[](numberOfLoans);
        uint256 j = 0;
        for (uint256 i = 0; i < loans.length; i++) {
            Loan memory loan = loans[i];
            if (loan.lender == _msgSender()) {
                if (state == LoanState.all) {
                    myLoans[j++] = loan;
                } else if (state == loan.state) {
                    myLoans[j++] = loan;
                }
            }
        }
        return myLoans;
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return interfaceId == IS_ERC721;
    }

    function calculateRepaymentAmount(uint256 principal, uint256 duration)
        public
        view
        returns (uint256)
    {
        uint256 interest = (((principal * interestRate) / 100) *
            (duration / 365)) / 1 days;
        return principal + interest / 100;
    }
}
