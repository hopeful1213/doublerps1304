pragma solidity ^0.4.16;

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract RSPLedger is usingOraclize {    
     address public whereToSendFee;          //Platform fee collector address     
     uint public totalLrCount = 0;           //Total count of RSPRequest created  
     uint public __leaderStat = 10;
     uint public __challengerStat = 10;
     uint [6] public  __challengerValue;
     address public leaderAdd__;
     address public testAdd__;
     bytes32 public test_queryId;
     address public playlAddr;
     mapping (uint => address) lrs;                           
     mapping (address => mapping(uint => uint [6])) rspleaderValueList;
     mapping (address => mapping(uint => uint [6])) rspchallengeValueList;
     mapping (address => mapping(uint => uint)) randomValueList;
     mapping (address => mapping(uint => uint )) leaderStat;
     mapping (address => mapping(uint => uint )) rspStat;
	 mapping (address => mapping(uint => uint )) bet;
	 mapping (bytes32 => address) leaderAddr;
	 mapping (bytes32 => address) challengerAddr;
	 mapping (bytes32 => uint) leaderKey;
	 mapping (uint => ConInfo) contractKey;
     uint safeGas = 23000;
     uint oraclizeFee = 0.0045 ether;
     uint256 feeAmount = 0.01 ether;
     uint256 betAmount = 0.2 ether;
     
	 	 
	struct ConInfo {
		address myleaderAddress;
		uint mydateNow;
		uint countKey;

	}
	function RSPLedger(address _whereToSendFee){
    	 whereToSendFee = _whereToSendFee;   
    } 
      
     function getLrCount() constant returns(uint){ return totalLrCount; }     
     function getLrState(address leaderAddr, uint dateNow) constant returns (uint){  return rspStat[leaderAddr][dateNow]; }         
     function getRSPInfo(uint _countKey) constant returns (address, uint, uint, uint, uint, unit){
       //  leaderAddress, rspConDate, ConState, leaderBetAmount, challengerStat
       return  (contractKey[countKey].myleaderAddress, contractKey[countKey].mydateNow, 
       rspStat[contractKey[countKey].myleaderAddress][contractKey[countKey].mydateNow], 
       bet[contractKey[countKey].myleaderAddress][contractKey[countKey].mydateNow], 
       leaderStat[contractKey[countKey].myleaderAddress][contractKey[countKey].mydateNow], contractKey[_countKey].countKey);
     }
     function getRSPresult(address _myleaderAddr, uint _mydateNow) constant returns (uint[6], uint[6], uint, uint){  
		   //leader : res[0], challenge : res[1], random : res[2], win : res[3]			
			return (rspleaderValueList[_myleaderAddr][_mydateNow],rspchallengeValueList[_myleaderAddr][_mydateNow],randomValueList[_myleaderAddr][_mydateNow],rspStat[_myleaderAddr][_mydateNow]); 
	 }     
     function newLrAndSetData(uint [6] leaderValue, uint dateNow) payable returns(address)
     {                     
        __challengerValue = leaderValue;
        if(msg.value != 0.5 ether && msg.value != 0.1 ether) revert();
     	if(leaderValue[0] == leaderValue[1] || leaderValue[2] == leaderValue[3] || leaderValue[4] == leaderValue[5]) revert();
		rspleaderValueList[msg.sender][dateNow] = leaderValue;
		bet[msg.sender][dateNow] = msg.value;
		leaderStat[msg.sender][dateNow] = 1;
		leaderAdd__ = msg.sender;
		contractKey[totalLrCount].myleaderAddress = msg.sender;
		contractKey[totalLrCount].mydateNow = dateNow;
		contractKey[totalLrCount].countKey = totalLrCount;
        totalLrCount++;                      
        return msg.sender;            	           
     }      
     function playGame(uint [6] _challengerValue, address _leaderAddr, uint _dateNow) payable {
        
		__challengerValue = _challengerValue;
		__leaderStat = leaderStat[_leaderAddr][_dateNow];
		leaderAdd__ = msg.sender;
		if(leaderStat[_leaderAddr][_dateNow] != 1) revert();
		if(msg.value != 0.5 ether && msg.value != 0.1 ether) revert();
        if(_challengerValue[0] == _challengerValue[1] || _challengerValue[2] == _challengerValue[3] || _challengerValue[4] == _challengerValue[5]) revert();
        bet[_leaderAddr][_dateNow] += msg.value;
		rspchallengeValueList[_leaderAddr][_dateNow] = _challengerValue;
	    leaderStat[_leaderAddr][_dateNow]++; 	     
        bytes32 queryId = oraclize_query("WolframAlpha", "random number between 0 and 63");
        leaderAddr[queryId] = _leaderAddr;
        challengerAddr[queryId] = msg.sender;
        leaderKey[queryId] = _dateNow;
    }   
    function __callback(bytes32 _queryId, string result)
    { 
            uint randomNumber = parseInt(result);		
       		setRandom(randomNumber, _queryId);
    }    
    function setRandom(uint _randomValue, bytes32 _queryId) payable{
     randomValueList[leaderAddr[_queryId]][leaderKey[_queryId]] = _randomValue;
     address rspleaderAddr = leaderAddr[_queryId];
     uint    rspleaderKey = leaderKey[_queryId];
     uint [6] rspleaderValueList_temp = rspleaderValueList[rspleaderAddr][leaderKey[_queryId]];
     uint [6] rspchallengeValueList_temp = rspchallengeValueList[rspleaderAddr][leaderKey[_queryId]];
     uint rspDateNow = leaderKey[_queryId];

				whereToSendFee.transfer(feeAmount);				
				uint rst = getWhoWin(_randomValue, rspleaderValueList_temp, rspchallengeValueList_temp);
      	
		    	if(rst == 1){
		    		  rspleaderAddr.transfer(betAmount - feeAmount - oraclizeFee - safeGas);	
		    		  rspStat[rspleaderAddr][rspleaderKey] = 4;			
		    	}
		    	else if(rst == 2){
		    	     challengerAddr[_queryId].transfer(betAmount  - feeAmount - oraclizeFee - safeGas);
		    		  rspStat[rspleaderAddr][rspleaderKey] = 5;			
		    	}
		    	else if(rst == 5){
		    		revert();
		    	}	    	
	 }
	 
     function getWhoWin(uint _myrandomValue, uint [6] rspleaderValueList, uint [6] rspchallengeValueList) constant returns(uint){ 

     	// round1   
      	uint roundRST = 0;
        uint  [2] _randomValue;
        _randomValue[0] = _myrandomValue % 2; 
      	_randomValue[1] = (_myrandomValue/2) % 2; 
     	roundRST = getWin(rspleaderValueList[_randomValue[0]],rspchallengeValueList[_randomValue[1]]); 
     	if(roundRST != 0) return roundRST; 
     	// round2
      	_randomValue[0] = (_myrandomValue/4) % 2; 
      	_randomValue[1] = (_myrandomValue/8) % 2; 
     	roundRST = getWin(rspleaderValueList[_randomValue[0]+2],rspchallengeValueList[_randomValue[1]+2]);
     	if(roundRST != 0) return roundRST;
     	// round3
     	_randomValue[0] = (_myrandomValue/16) % 2; 
      	_randomValue[1] = (_myrandomValue/32) % 2; 
     	roundRST = getWin(rspleaderValueList[_randomValue[0]+4],rspchallengeValueList[_randomValue[1]+4]);
     	if(roundRST != 0) return roundRST;      	
      	return 1;
  	}
   
    function getWin(uint ld, uint cl) returns (uint){
    	if((ld == 0 && cl == 0) || (ld == 1 && cl == 1) || (ld == 2 && cl == 2)) return 0;
    	if((ld == 0 && cl == 1) || (ld == 1 && cl == 2) || (ld == 2 && cl == 0)) return 2;
    	if((ld == 0 && cl == 2) || (ld == 1 && cl == 0) || (ld == 2 && cl == 1)) return 1;    
    	return 5;
    }
    function() payable {
    }   

	  
}
// test001
// hm
