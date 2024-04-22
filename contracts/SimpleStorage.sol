// SPDX-License-Identifier: UNKNOWN (this is a comment)

pragma solidity ^0.8.24;

contract SimpleStorage {
  uint256 favoriteNumber;
  bool favoriteBool;

  struct People {
    uint256 favoriteNumber;
    string name;
  }
  People public person = People({favoriteNumber: 2, name: 'Patrick'});
  People[] public people;
  mapping(string => uint256) public nameToFavoriteNumber;

  ///存储值，是一个非view函数，会改变合约的状态
  function store(uint256 _favoriteNumber) public {
    favoriteNumber = _favoriteNumber;
  }

  ///返回值，是一个view函数，不会改变合约的状态
  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  ///增加人员
  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }

  ///返回人员
  function getPerson() public view returns (People[] memory) {
    return people;
  }
}
