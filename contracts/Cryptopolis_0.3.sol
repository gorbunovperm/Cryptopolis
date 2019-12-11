pragma solidity 0.4.25;

contract Cryptopolis {
    uint256 public price = 0.001 ether; // 100 CLO
    uint256 public croupierId = 0;
    uint256 public playersCount = 0;
    uint256 public maxPlayers = 5;
    address public owner;
    
    uint256 constant fieldsAmount = 40;
    uint256 constant goPassedReward = 200;
    uint256 constant initialFunds = 150;
    mapping(address => uint256) playerNumber;
    
    Field[40] public fields;
    Player[] public players;
    
    struct Field {
        //uint8 fieldType;
        int256 payment;
    }
    
    struct Player {
        address addr;
        uint256 position;
        uint256 balance;
        bool inGame;
    }
    
    event PositionChanged(address player, uint256 stepsNumber, uint256 newPosition);
    event BalanceChanged(address player, uint256 newBalance);
    event NewPlayer(address player, uint256 skin, uint256 balance);
    event PlayerLost(address player);
    
    
    constructor() public {
        uint256 hash;
        uint256 salt;
        int256 res;
        
        for(uint256 i = 0; i < fields.length; i++) {
            hash = uint256(blockhash(block.number - 1));
            salt = uint256(blockhash(block.number - 2)) % (100-i);
            res = int256(hash % 200) - int256(salt);
            
            fields[i] = Field({payment: res});
        }
        
        owner = msg.sender;
    }
    
    function() payable public {
        emit BalanceChanged(msg.sender, 111);
        emit PositionChanged(msg.sender, 3, 3);
    }
    
    function buyTicket() payable public {
        uint256 number = playerNumber[msg.sender];
        require(number == 0);
        require(msg.value == price);
        require(players.length < maxPlayers);
        Player memory p = Player({
            addr: msg.sender,
            position: 0, 
            balance: initialFunds, 
            inGame: true});
        players.push(p);
        playerNumber[msg.sender] = players.length;

        emit NewPlayer(msg.sender, playerNumber[msg.sender] - 1, initialFunds);
        emit BalanceChanged(msg.sender, initialFunds);
        emit PositionChanged(msg.sender, 0, 0);
    }
    
    function makeMoves() public {
        //address croupierAddress = players[croupierId];
        require(players[croupierId].addr == msg.sender);
        
        for (uint i = 0; i < players.length; i++) {
            _makeMove(i);
        }
        
        croupierId++;
        if (croupierId == players.length) {
            croupierId = 0;
        }
    }
    
    function _makeMove(uint256 playerId) private {
        Player memory player = players[playerId];
        if (!player.inGame) return;

        uint256 stepsNumber = _countSteps(player.addr);
        uint256 position = players[playerId].position;
        bool goPassed = false;
        
        position += stepsNumber;
        if (position >= fieldsAmount) {
            position = position - fieldsAmount;
            goPassed = true;
        }
        require(position < fieldsAmount);
        players[playerId].position = position;
        
        if (goPassed) {
            players[playerId].balance += goPassedReward;
        }
        
        // Check the payment in the field.
        // TODO: Check this condition.
        if (int256(players[playerId].balance) + fields[position].payment >= 0) {
            players[playerId].balance = uint256(int256(players[playerId].balance) + fields[position].payment);
        } else {
            // TODO: Should be implemented more behaviours, like sale of buildings.
            _playerLost(playerId);
        }
        
        emit BalanceChanged(player.addr, players[playerId].balance);
        emit PositionChanged(player.addr, stepsNumber, players[playerId].position);
    }
    
    function _countSteps(address _player) public view returns(uint256) { // make Private
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), _player))) % 12;
    }
    
    function _playerLost(uint256 _playerId) public { // private
        Player memory player = players[_playerId];
        require(player.inGame);
        require(players.length != 0);
        
        //delete players[playersCount] = msg.sender;
        players[_playerId].inGame = false;
        players[_playerId].balance = 0;
        players[_playerId].position = 0;
        emit PlayerLost(player.addr);
    }
    

    function destruct() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
    
    
    // View functions
    
    function getPlayersCount() public view returns(uint256) {
        return players.length;
    }
    
    function getPlayer(uint256 _playerId) public view returns(address addr, uint256 position, uint256 balance, bool inGame) {
        return (players[_playerId].addr, players[_playerId].position, players[_playerId].balance, players[_playerId].inGame);
    }
    
    function getFieldsCount() public view returns(uint256) {
        return fieldsAmount;
    }
    
    function getFields(uint256 _fieldId) public view returns(int256 payment) {
        payment = fields[_fieldId].payment;
        return payment;
    }
    
    function debug_position() public view returns(uint256, uint256, uint256, uint256) {
        return (players[0].position, players[1].position, players[2].position, players[3].position);
    }
    
}