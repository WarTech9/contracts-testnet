//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CheddaDappExplorer.sol";
import "../common/CheddaAddressRegistry.sol";
import "hardhat/console.sol";

struct Dapp {
    uint16 index;
    string name;
    string network;
    uint8 chainID;
    address contractAddress;
    string metadataURI;
    bool isFeatured;
    uint256 listed;
    uint256 updated;
}

struct DappReview {
    uint256 timestamp;
    string metadataURI;
}

interface IStore {
    function addDapp(
        string memory name,
        string memory network,
        uint8 chainId,
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
    Dapp[] private _dapplist;
    uint16 private _ratingPrecision = 100;

    mapping(address => Dapp) public _dapps;
    mapping(address => uint256) public likes;
    mapping(address => uint256) public dislikes;
    mapping(address => uint16) public ratings;
    mapping(address => mapping(address => bool)) private appAdmins;
    mapping(address => DappReview[]) public reviews;
    mapping(string => address[]) public categories;

    CheddaAddressRegistry public registry;

    function updateRegistry(address registryAddress) external onlyOwner() {
        registry = CheddaAddressRegistry(registryAddress);
        console.log("updating registry to %s", registryAddress);
    }

    function addDapp(
        string memory name,
        string memory network,
        uint8 chainId,
        address contractAddress,
        string memory category,
        string calldata uri
    ) public override onlyOwner() {
        // require(dapp.contractAddress != address(0), "Address is zero");
        // require(_dapps[contractAddress].contractAddress == address(0), "Dapp already exists");
        uint16 index = _dappCount++;
        Dapp memory dapp = Dapp({
            index: index,
            name: name,
            network: network,
            chainID: chainId,
            contractAddress: contractAddress,
            metadataURI: uri,
            isFeatured: false,
            listed: block.timestamp,
            updated: block.timestamp
        });
        _dapps[contractAddress] = dapp;
        categories[category].push(contractAddress);
        _dapplist.push(dapp);

        emit DappAdded(name, contractAddress);
    }

    function removeDapp(address contractAddress) public override onlyOwner() {
        require(contractAddress != address(0), "Address should not be zero");
        require(
            _dapps[contractAddress].contractAddress != address(0),
            "Dapp does not exist"
        );

        Dapp memory dapp = _dapps[contractAddress];
        delete _dapps[contractAddress];
        delete _dapplist[dapp.index];
        delete likes[contractAddress];
        delete dislikes[contractAddress];
        _dapplist[dapp.index] = _dapplist[_dapplist.length - 1];
        _dapplist.pop();
        emit DappRemoved(_dapps[contractAddress].name, contractAddress);
    }

    function getDapp(address contractAddress)
        public
        view
        override
        returns (Dapp memory)
    {
        return _dapps[contractAddress];
    }

    function getDappAtIndex(uint256 index)
    public view
    returns (Dapp memory)
    {
        return _dapplist[index];
    }

    function dapps() public view override returns (Dapp[] memory) {
        return _dapplist;
    }

    function numberOfDapps() external view returns (uint256) {
        return _dapplist.length;
    }

    function likeDapp(address contractAddress) public {
        require(
            _dapps[contractAddress].contractAddress != address(0),
            "Dapp does not exist"
        );
        likes[contractAddress] += 1;
    }

    function unlikeDapp(address contractAddress) public {
        require(
            _dapps[contractAddress].contractAddress != address(0),
            "Dapp does not exist"
        );
        dislikes[contractAddress] += 1;
    }

    function getLikes(address contractAddress) public view returns (uint256) {
       require(
            _dapps[contractAddress].contractAddress != address(0),
            "Dapp does not exist"
        ); 
        return likes[contractAddress];
    }

    function getDislikes(address contractAddress) public view returns (uint256) {
       require(
            _dapps[contractAddress].contractAddress != address(0),
            "Dapp does not exist"
        ); 
        return dislikes[contractAddress];
    }

    function getReviews(address contractAddress)
        public
        view
        returns (DappReview[] memory)
    {
        return reviews[contractAddress];
    }

    function isCheddaStore() external override pure returns (bool) {
        return true;
    }


    function addDappAdmin(address contractAddress, address admin) public onlyOwner() {
        require(
            _dapps[contractAddress].contractAddress != address(0),
            "Dapp does not exist"
        );
        appAdmins[contractAddress][admin] = true;
    }

    function removeDappAdmin(address contractAddress, address admin) public onlyOwner() {
        require(
            _dapps[contractAddress].contractAddress != address(0),
            "Dapp does not exist"
        );
        require(
            appAdmins[contractAddress][admin] == true,
            "Address is not an admin"
        );

        appAdmins[contractAddress][admin] = false;
    }

    function featureDapp(address contractAddress, bool isFeatured) public onlyOwner() {
        require(contractAddress != address(0), "Address should not be zero");
        require(
            _dapps[contractAddress].contractAddress != address(0),
            "Dapp does not exist"
        ); 
        _dapps[contractAddress].isFeatured = isFeatured;
    }

    function getFeaturedDapps() public view returns (Dapp[] memory) {
        uint256 featuredCount = 0;
        for (uint256 i = 0; i < _dapplist.length; i++) {
            Dapp storage dapp = _dapps[_dapplist[i].contractAddress];
            if (dapp.isFeatured) {
                featuredCount++;
            }
        }
        Dapp[] memory matchingDapps = new Dapp[](featuredCount);
        featuredCount = 0;
        for (uint256 i = 0; i < _dapplist.length; i++) {
            Dapp memory dapp = _dapps[_dapplist[i].contractAddress];
            if (dapp.isFeatured) {
                matchingDapps[featuredCount] = dapp;
                featuredCount++;
            }
        }
        return matchingDapps;
    }

    function getDappsInCategory(string calldata category) public view returns (Dapp[] memory) {
        require(categories[category].length != 0, "Invalid category");
        address[] memory dappAddresses = categories[category];
        Dapp[] memory dappList = new Dapp[](dappAddresses.length);
        for (uint256 i = 0; i < dappAddresses.length; i++) {
            dappList[i] = _dapps[dappAddresses[i]];
        }
        return dappList;
    }

    function numberOfDappsInCategory(string calldata category) public view returns (uint256) {
       return categories[category].length;
    }

    function getNewDapps(uint256 listedSince) public view returns (Dapp[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < _dapplist.length; i++) {
            if (_dapplist[i].listed >= listedSince) {
                count++;
            }
        }
        Dapp[] memory matchingDapps = new Dapp[](count);
        count = 0;
        for (uint256 i = 0; i < _dapplist.length; i++) {
            if (_dapplist[i].listed >= listedSince) {
                matchingDapps[count] = _dapplist[i];
                count++;
            }
        }
        return matchingDapps;
    }


    // Popular dapps are once that have at least X number of ratings and a specified average rating.
    // Will transition to time-period based popularity
    function popularDapps() public view returns (Dapp[] memory) {
        CheddaDappExplorer explorer = CheddaDappExplorer(registry.dappStoreExplorer());
        uint256 count = 0;

        for (uint256 i = 0; i < _dapplist.length; i++) {
            if (explorer.averageRating(_dapplist[i].contractAddress) > 300 &&
                explorer.numberOfRatings(_dapplist[i].contractAddress) > 1) {
                count++;
            }
        }
        Dapp[] memory matchingDapps = new Dapp[](count);
        count = 0;
        for (uint256 i = 0; i < _dapplist.length; i++) {
            if (explorer.averageRating(_dapplist[i].contractAddress) > 300 &&
                explorer.numberOfRatings(_dapplist[i].contractAddress) > 1) {
                matchingDapps[count] = _dapplist[i];
                count++;
            }
        }
        return matchingDapps;
    }

}
