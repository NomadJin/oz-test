// src/index.js
const Web3 = require('web3');
const { setupLoader } = require('@openzeppelin/contract-loader');

async function main() {
  // Our code will go here
  const web3 = new Web3('http://localhost:7545');
  const loader = setupLoader({ provider: web3 }).web3;

  const address = '0x650930222EEEc388B68ee6Af3f4ddE7d039D7916';
  const box = loader.fromArtifact('Box', address);

  // Call the retrieve() function of the deployed Box contract
  const value = await box.methods.retrieve().call();
  console.log("Box value is", value);
}

main();