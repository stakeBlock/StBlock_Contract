// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

function exists(address[] storage _arr, address _account) view  returns (bool) {
    for (uint256 i = 0; i < _arr.length; i++) {
        if (_arr[i] == _account) {
            return true;
        }
    }
    return false;
}

function addAddress(address[] storage _arr, address _addr)  {
    if (!exists(_arr, _addr)) {
        _arr.push(_addr);
    }
}
