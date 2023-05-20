// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./Structs.sol";

function popValueFromUintArray(uint[] storage _arr, uint _value) {
    uint index = _arr.length;
    // find value
    for (uint i = 0 ; i < _arr.length; i++) {
        if (_arr[i] == _value) {
            index = i;
        }
    }
    // if no value
    if (index == _arr.length) {
        return;
    }
    // else remove value
    _arr[index] = _arr[_arr.length - 1];
    _arr.pop();
}

function enqueueUnstakeRequests(UnstakeRequest[] storage _arr, UnstakeRequest memory _value, uint _rear) returns (uint) {
    _arr.push(_value);
    return _rear+1;
}
function dequeueUnstakeRequests(UnstakeRequest[] storage _arr, uint _front, uint _rear) returns (uint) {
    require(_front < _rear, "Queue is empty");
    delete _arr[_front];
    return _front+1;
}
