import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("ArtBidexNFT", (m) => {
  const artBidexNFT = m.contract("ArtBidexNFT", []); 
  

  return { artBidexNFT };
});
