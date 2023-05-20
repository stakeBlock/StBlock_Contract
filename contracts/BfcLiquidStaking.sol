// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/BfcStaking.sol";

import "./lib/AddressUtils.sol";
import "./lib/Structs.sol";
import "./lib/ArrayUtils.sol";
import "hardhat/console.sol";


contract BfcLiquidStaking is Initializable, OwnableUpgradeable {
    //====== Contracts and Addresses ======//
    IERC20 private stBFC;
    BfcStaking private bfcStaking;
    address public candidate;

    //====== variables ======//
    uint256 public totalStaked;
    uint256 public totalDistributedRewards;
    bool public initialized;
    uint public unstakeRequestsFront;
    uint public unstakeRequestsRear;

    //------ Array and Mapping ------//
    mapping (address => uint256) public stakedAmount;
    UnstakeRequest[] public unstakeRequests;


    //------ addresses status ------//
    address[] public addressList;
    uint public totalAddressNumber;

    //------ Events ------//
    event Stake(uint256 indexed _amount);
    event Unstake(uint256 indexed _amount);

    // ====== Modifiers ====== //
    modifier isInitialized {
        require(initialized, "BfcLiquidStaking: contract is not initialized");
        _;
    }


    //====== Initializer ======//
    function initialize(address _stBFCAddr, address _bfcStakingAddr, address _candidateAddr) initializer public {
        __Ownable_init();

        stBFC = IERC20(_stBFCAddr);
        bfcStaking = BfcStaking(_bfcStakingAddr);
        candidate = _candidateAddr;
        initialized = false;
        unstakeRequestsFront = 0;
        unstakeRequestsRear = 0;
    }

    //====== Getter Functions ======//
 function getUnstakeRequestsLength() public view returns (uint) {
        return unstakeRequestsRear - unstakeRequestsFront;
    }
    //====== Setter Functions ======//
    function setCandidate(address _candidate) external onlyOwner {
        candidate = _candidate;
    }

    //====== Service Functions ======//
    function stake() external payable isInitialized {
        uint _amount = msg.value;

        // nominate candidate
        bfcStaking.nominator_bond_more(candidate, _amount); 

        // add address to address list if it is not in the list
        addAddress(addressList, msg.sender);
        totalAddressNumber = addressList.length;

        // update totalStaked
        totalStaked += _amount;

        // update stakedAmount
        stakedAmount[msg.sender] += _amount;

        // mint stBFC token to msg.sender
        stBFC.mintToken(msg.sender, _amount);


        // emit Stake event
        emit Stake(_amount);
    }

    function spreadRewards() external onlyOwner isInitialized {
        // get total value
        (, uint256 totalValue,,,,,,,,,) = bfcStaking.nominator_state(address(this));
        // get reward amount
        uint totalRewardAmount = totalValue - totalStaked - totalDistributedRewards; 
        for (uint i = 0; i < addressList.length; i++) {
            address account = addressList[i];
            uint rewardAmount = totalRewardAmount * stakedAmount[account] / totalStaked;
            // update stakedAmount
            stakedAmount[account] += rewardAmount;
            stBFC.mintToken(account, rewardAmount);
        }
        // update totalDistributedRewards
        totalDistributedRewards += totalRewardAmount;
    }

    function createUnstakeRequest (uint256 _amount) external isInitialized {
        require(stakedAmount[msg.sender] >= _amount, "BfcLiquidStaking: unstake amount is more than staked amount");
        // check msg.sender's balance
        require(stBFC.balanceOf(msg.sender) >= _amount, "BfcLiquidStaking: unstake amount is more than stBFC balance");
        // burn stBFC token from msg.sender
        stBFC.burnToken(msg.sender, _amount);

        // update stakedAmount
        stakedAmount[msg.sender] -= _amount;

        // update totalStaked
        totalStaked -= _amount;

        // create unstake request
        UnstakeRequest memory request = UnstakeRequest(msg.sender, _amount, block.timestamp, false);

        // add unstake request to unstakeRequests
        unstakeRequestsRear = enqueueUnstakeRequests(unstakeRequests, request, unstakeRequestsRear);

        // emit Unstake event
        emit Unstake(_amount);
    }

    function unstake() external onlyOwner {
        uint front = unstakeRequestsFront;
        uint rear = unstakeRequestsRear;
        uint totalAmount = 0;
        for (uint i = front; i < rear; i++) {
            if (!unstakeRequests[i].requested) {
                totalAmount += unstakeRequests[i].amount;
                unstakeRequests[i].requested = true;
            }
        }

        // unstake
        bfcStaking.schedule_nominator_bond_less(candidate, totalAmount);
    }

    function claimUnstakedAmount() external {

    }

    function sendUnstakedAmount() external  {
        uint front = unstakeRequestsFront;
        uint rear = unstakeRequestsRear;
        for (uint i = front; i< rear; i++) {
            if (unstakeRequests[i].amount > address(this).balance) {
                break;
            }
            // remove first element of unstakeRequests
            unstakeRequestsFront = dequeueUnstakeRequests(unstakeRequests, unstakeRequestsFront, unstakeRequestsRear);
            (bool sent, ) = unstakeRequests[i].recipient.call{value : unstakeRequests[i].amount}("");
            require(sent, "BfcLiquidStaking: failed to send unstaked amount");
        }
    }

    //====== utils Functions ======//
    function initialStake() public payable onlyOwner {
        // check msg.value
        console.log("msg.value: ", msg.value);
        require(msg.value == 1000 * 10**18, "BfcLiquidStaking: invalid transfer amount");
        // get required information
        uint candidateNominationCount = bfcStaking.candidate_nomination_count(candidate);
        uint nominatorNominationCount = bfcStaking.nominator_nomination_count(msg.sender);

        // nominate candidate 1000 BFC
        bfcStaking.nominate(candidate, 1000*10**18, candidateNominationCount, nominatorNominationCount); 

        // set initialized to true
        initialized = true;
    }

    // for test
    function unstakeAll() public onlyOwner {
        bfcStaking.schedule_leave_nominators();
    }

    // for test
    function transferBfcToContract() public payable {
        require(msg.value > 0, "BfcLiquidStaking: transfer amount is zero");
    }
    // for test
    function transferBfcToOwner(address _receiver) public onlyOwner {
        (bool sent, ) = _receiver.call{value : address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}
