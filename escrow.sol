// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;


//Author:  Yogesh K

contract EscrowContract
{

    address public customer;
    address public freelancer;

    struct Escrow
    {
        string planName; // fixed, hourly or more etc.
        address payable customer;
        address payable freelancer;
        uint requiredAmount; // depositing or withdrawing
        bytes32 escrowId;
        bool submitWork;  // has to be submitted by the freelancer
        bool approved;  // has to be approved the customer
        State state;
    }

    // enum for state control
    enum State { INACTIVE, PENDING, ACTIVE, CLOSED }

    mapping(bytes32 => Escrow) public plans;

    // modifiers (pre condition check)
    modifier onlyCustomer() {
        require(msg.sender == customer, 'Only customer!');
        _;
    }

    modifier inState(bytes32 _escrowId, State state) {
        require(plans[_escrowId].state == state, 'Invalid State!');
        _;
    }

    modifier isApproved(bytes32 _escrowId) {
        require(plans[_escrowId].approved, 'Work must be approved!');
        _;
    }
    modifier isSubmitted(bytes32 _escrowId) {
        require(plans[_escrowId].submitWork, 'Work must be submitted!');
        _;
    }



    constructor(address _freelancer)
    {
        customer = msg.sender; // owner of the contract
        freelancer = _freelancer;
    }

    function idGenerator()
                        external
                        view
                        onlyCustomer()
                        returns (bytes32)
    {
        return keccak256(abi.encode(customer,
                                    freelancer,
                                    block.timestamp
                                   )
                        );


    }

    function addEscrowPlan(string memory _planName,
                           address payable _customer,
                           address payable _freelancer,
                           uint _requiredAmount,
                           bytes32 _escrowId
                           )
                           external
                           onlyCustomer()
                           inState(_escrowId, State.INACTIVE)
    {
        plans[_escrowId] = Escrow(_planName,
                                  _customer,
                                  _freelancer,
                                  _requiredAmount, // set some initial value
                                  _escrowId,
                                  false,
                                  false,
                                  State.PENDING
                                );

    }

    function depositEther(bytes32 _escrowId)
                          external
                          payable
                          onlyCustomer()
                          inState(_escrowId, State.PENDING)
    {

       require(msg.value >= plans[_escrowId].requiredAmount, 'Invalid amount provided!');
       plans[_escrowId].requiredAmount = msg.value; // msg.value contains the ether
       plans[_escrowId].state = State.ACTIVE;

    }

    // to be called by customer only
    function approveWork(bytes32 _escrowId)
                        external
                        onlyCustomer()
                        isSubmitted(_escrowId)
                        inState(_escrowId,State.ACTIVE)
    {
         plans[_escrowId].approved = true;
    }



        // to be called by freelancer
    function withdrawEther(bytes32 _escrowId)
                           external
                           payable
                           isApproved(_escrowId)
                           inState(_escrowId,State.ACTIVE)

    {
        plans[_escrowId].freelancer.transfer(plans[_escrowId].requiredAmount);
        plans[_escrowId].state = State.CLOSED;

    }


    // to be called by freelancer
    function submitWork(bytes32 _escrowId)
                        external
                        inState(_escrowId,State.ACTIVE)
    {
         plans[_escrowId].submitWork = true;
    }


}

contract Freelancer
{
    bytes32 escrowId;
    address escrowAddress;

    function setEscrowID(bytes32 _escrowID) external
    {
        escrowId = _escrowID;
    }

    function setEscrowAddress(address _escrowAddr) external
    {
        escrowAddress = _escrowAddr;
    }

    function callsubmitWork() external
    {
        EscrowContract escrow = EscrowContract(escrowAddress);
        escrow.submitWork(escrowId);
    }

    function callwithdrawEther() external
    {
        EscrowContract escrow = EscrowContract(escrowAddress);
        escrow.withdrawEther(escrowId);
    }

}
