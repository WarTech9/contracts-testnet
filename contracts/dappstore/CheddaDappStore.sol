//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CheddaDappExplorer.sol";
import "../common/CheddaAddressRegistry.sol";
import "hardhat/console.sol";

struct Dapp {
    uint16 index;
    string name;
    uint64 chainID;
    address contractAddress;
    string metadataURI;
    bool isFeatured;
    uint256 listed;
    uint256 updated;
}

struct DappRating {
    uint256 averageRating;
    uint256 numberOfRatings;
}

struct DappWithRating {
    Dapp dapp;
    DappRating rating;
}

interface IStore {
    function addDapp(
        string memory name,
        uint64 chainId,
        address contractAddress,
        string memory category,
        string calldata uri
    ) external;

    function removeDapp(address) external;

    function dapps() external returns (Dapp[] memory);

    function getDapp(address contractAddress)
        external
        view
        returns (Dapp memory);

    function isCheddaStore() external pure returns (bool);
}

contract CheddaDappStore is Ownable, IStore {
    event DappAdded(string indexed name, address indexed contractAddress);
    event DappRemoved(string indexed name, address indexed contractAddress);

    error DappNotFound();

    uint16 private _dappCount;
    address[] private _dappAddresses;

    mapping(address => Dapp) public _dapps;
    mapping(address => mapping(address => bool)) private dappAdmins;
    mapping(string => address[]) public categories;

    ICheddaAddressRegistry public registry;

    modifier dappExists(address contractAddress) {
        require(
            _dapps[contractAddress].contractAddress != address(0),
            "Invalid address"
        );
        _;
    }

    modifier isDappAdmin(address contractAddress, address adminAddress) {
        require(dappAdmins[contractAddress][adminAddress], "Not dapp admin");
        _;
    }

    function updateRegistry(address registryAddress) external onlyOwner {
        registry = ICheddaAddressRegistry(registryAddress);
    }

    function addDapp(
        string memory name,
        uint64 chainId,
        address contractAddress,
        string memory category,
        string calldata uri
    ) public override onlyOwner {
        require(contractAddress != address(0), "Zero address");
        require(
            _dapps[contractAddress].contractAddress == address(0),
            "Dapp exists"
        );
        uint16 index = _dappCount++;
        Dapp memory dapp = Dapp({
            index: index,
            name: name,
            chainID: chainId,
            contractAddress: contractAddress,
            metadataURI: uri,
            isFeatured: false,
            listed: block.timestamp,
            updated: block.timestamp
        });
        _dapps[contractAddress] = dapp;
        categories[category].push(contractAddress);
        _dappAddresses.push(contractAddress);

        emit DappAdded(name, contractAddress);
    }

    function removeDapp(address contractAddress)
        public
        override
        onlyOwner
        dappExists(contractAddress)
    {
        Dapp storage dapp = _dapps[contractAddress];
        delete _dapps[contractAddress];
        delete _dappAddresses[dapp.index];
        _dappAddresses[dapp.index] = _dappAddresses[_dappAddresses.length - 1];
        _dappAddresses.pop();
        emit DappRemoved(_dapps[contractAddress].name, contractAddress);
    }

    function updateDappMetadata(
        address contractAddress,
        string calldata metadataURI
    ) public dappExists(contractAddress)  isDappAdmin(contractAddress, _msgSender()){
        _dapps[contractAddress].metadataURI = metadataURI;
    }

    function getDapp(address contractAddress)
        public
        view
        override
        dappExists(contractAddress)
        returns (Dapp memory)
    {
        return _dapps[contractAddress];
    }

    function getDappAtIndex(uint256 index) public view returns (Dapp memory) {
        require(index < _dappAddresses.length, "Invalid index");
        address dappAddress = _dappAddresses[index];
        return _dapps[dappAddress];
    }

    function dapps() public view override returns (Dapp[] memory) {
        Dapp[] memory dappList = new Dapp[](_dappAddresses.length);
        for (uint256 i = 0; i < _dappAddresses.length; i++) {
            dappList[i] = _dapps[_dappAddresses[i]];
        }
        return dappList;
    }

    function dappsWithRatings() public view returns (DappWithRating[] memory) {
        DappWithRating[] memory dappList = new DappWithRating[](
            _dappAddresses.length
        );
        for (uint256 i = 0; i < _dappAddresses.length; i++) {
            dappList[i] = DappWithRating({
                dapp: _dapps[_dappAddresses[i]],
                rating: _getDappRating(_dappAddresses[i])
            });
        }
        return dappList;
    }

    function numberOfDapps() external view returns (uint256) {
        return _dappAddresses.length;
    }

    function isCheddaStore() external pure override returns (bool) {
        return true;
    }

    function addDappAdmin(address contractAddress, address admin)
        public
        onlyOwner
        dappExists(contractAddress)
    {
        dappAdmins[contractAddress][admin] = true;
    }

    function removeDappAdmin(address contractAddress, address admin)
        public
        onlyOwner
        dappExists(contractAddress)
    {
        require(dappAdmins[contractAddress][admin] == true, "Not admin address");

        dappAdmins[contractAddress][admin] = false;
    }

    function setFeaturedDapp(address contractAddress, bool isFeatured)
        public
        onlyOwner
        dappExists(contractAddress)
    {
        _dapps[contractAddress].isFeatured = isFeatured;
    }

    function featuredDapps() public view returns (DappWithRating[] memory) {
        uint256 featuredCount = 0;
        for (uint256 i = 0; i < _dappAddresses.length; i++) {
            Dapp storage dapp = _dapps[_dappAddresses[i]];
            if (dapp.isFeatured) {
                featuredCount++;
            }
        }

        DappWithRating[] memory matchingDapps = new DappWithRating[](
            featuredCount
        );
        featuredCount = 0;
        for (uint256 i = 0; i < _dappAddresses.length; i++) {
            Dapp memory dapp = _dapps[_dappAddresses[i]];
            DappRating memory rating = _getDappRating(_dappAddresses[i]);
            if (dapp.isFeatured) {
                matchingDapps[featuredCount] = DappWithRating({
                    dapp: dapp,
                    rating: rating
                });
                featuredCount++;
            }
        }
        return matchingDapps;
    }

    function dappsInCategory(string calldata category)
        public
        view
        returns (DappWithRating[] memory)
    {
        if (categories[category].length == 0) {
            return new DappWithRating[](0);
        }
        address[] memory addresses = categories[category];
        DappWithRating[] memory matchingDapps = new DappWithRating[](
            addresses.length
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            console.log("address is %s", addresses[i]);
            Dapp storage dapp = _dapps[addresses[i]];
            DappRating memory rating = _getDappRating(addresses[i]);
            matchingDapps[i] = DappWithRating({dapp: dapp, rating: rating});
        }
        return matchingDapps;
    }

    function numberOfDappsInCategory(string calldata category)
        public
        view
        returns (uint256)
    {
        return categories[category].length;
    }

    function newDapps(uint256 listedSince)
        public
        view
        returns (DappWithRating[] memory)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < _dappAddresses.length; i++) {
            Dapp storage dapp = _dapps[_dappAddresses[i]];
            if (dapp.listed >= listedSince) {
                count++;
            }
        }
        DappWithRating[] memory matchingDapps = new DappWithRating[](count);
        count = 0;
        for (uint256 i = 0; i < _dappAddresses.length; i++) {
            Dapp storage dapp = _dapps[_dappAddresses[i]];
            DappRating memory rating = _getDappRating(_dappAddresses[i]);
            if (dapp.listed >= listedSince) {
                matchingDapps[count] = DappWithRating({
                    dapp: dapp,
                    rating: rating
                });
                count++;
            }
        }
        return matchingDapps;
    }

    // Popular dapps are once that have at least X number of ratings and a specified average rating.
    // Will transition to time-period based popularity

    function popularDapps() public view returns (DappWithRating[] memory) {
        uint256 count = 0;

        for (uint256 i = 0; i < _dappAddresses.length; i++) {
            DappRating memory rating = _getDappRating(_dappAddresses[i]);
            if (rating.averageRating > 300 && rating.numberOfRatings > 0) {
                count++;
            }
        }
        DappWithRating[] memory matchingDapps = new DappWithRating[](count);
        count = 0;
        for (uint256 i = 0; i < _dappAddresses.length; i++) {
            DappRating memory rating = _getDappRating(_dappAddresses[i]);
            if (rating.averageRating > 300 && rating.numberOfRatings > 0) {
                Dapp storage dapp = _dapps[_dappAddresses[i]];
                DappWithRating memory dappWithRatings = DappWithRating({
                    dapp: dapp,
                    rating: rating
                });
                matchingDapps[count] = dappWithRatings;
                count++;
            }
        }
        return matchingDapps;
    }

    function _getDappRating(address contractAddress)
        internal
        view
        returns (DappRating memory)
    {
        IStoreExplorer explorer = IStoreExplorer(registry.dappStoreExplorer());
        uint256 averageRating = explorer.averageRating(contractAddress);
        uint256 numberOfRatings = explorer.numberOfRatings(contractAddress);
        return
            DappRating({
                averageRating: averageRating,
                numberOfRatings: numberOfRatings
            });
    }
}
