const hre = require("hardhat");

async function main() {
  const SantaNFT = await hre.ethers.getContractFactory("SantaNFT");
  const santaNFT = await SantaNFT.deploy();

  await santaNFT.deployed();

  console.log("SantaNFT deployed to:", santaNFT.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
