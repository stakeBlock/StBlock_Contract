// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

struct UnstakeRequest{
    address recipient;
    uint amount;
    uint requestTime;
    bool requested;
}