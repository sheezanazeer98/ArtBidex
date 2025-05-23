import { ConnectButton } from "./components/ConnectButton";
import { InfoList } from "./components/InfoList";
import { ActionButtonList } from "./components/ActionButtonList";


export default function Home() {
  return (
    <div className="">

     <div className={"pages"}>
      <h1>ArtBidex </h1>
      <ConnectButton />
      <ActionButtonList />
      <InfoList />
    </div>

    </div>
  );
}
