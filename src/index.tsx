import {
  definePlugin,
  Navigation,
  ServerAPI,
  showModal,
  staticClasses,
  useParams
} from "decky-frontend-lib";
import { FaBoxOpen } from "react-icons/fa";

import { Content } from "./ContentTabs";
import { About } from "./About";
import { addAchievement, getAchievementDetails, toastAchievement, toastFactory } from "./Utils/achievements";
import Logger from "./Utils/logger";
import { MainMenuModal } from "./MainMenuModal";
import { DownloadsPage } from "./Components/DownloadsPage";
import { installQueue } from "./Utils/installQueue";




//@ts-ignore
export default definePlugin((serverApi: ServerAPI) => {


  toastFactory(serverApi.toaster);
  let selectPressed = false;
  let startPressed = false;
  let l3Pressed = false;
  let r3Pressed = false;

  const unregister = SteamClient.Input.RegisterForControllerInputMessages(
    (e) => {
      if (Array.isArray(e)) {
        if (e[0]) {
          if (e[0].nA == 35) {
            selectPressed = e[0].bS;
          }
          if (e[0].nA == 36) {
            startPressed = e[0].bS;
          }
          if (e[0].nA == 25) {
            l3Pressed = e[0].bS;
          }
          if (e[0].nA == 41) {
            r3Pressed = e[0].bS;
          }
        }
      }

      if (l3Pressed && r3Pressed && localStorage.getItem('gv_doubleStick') === 'true') {
        Navigation.CloseSideMenus();
        showModal(<MainMenuModal serverApi={serverApi} />);

      }
    })



  const currentTime = new Date();
  const currentHour = currentTime.getHours();
  const currentMinute = currentTime.getMinutes();

  if (currentHour === 0 && currentMinute >= 0 && currentMinute <= 15) {
    addAchievement("MTAx")
  }
  const currentDate = new Date();
  if (currentDate.getDay() === 5 && currentDate.getDate() === 13) {
    addAchievement("MTEw")
  }

  serverApi.routerHook.addRoute(
    "/gamevault-content/:initActionSet/:initAction",
    () => {
      const { initActionSet, initAction } = useParams<{ initActionSet: string; initAction: string }>();
      return <Content key={initActionSet + "_" + initAction} serverAPI={serverApi} initActionSet={initActionSet} initAction={initAction} />;
    },
    {
      exact: true,
    }
  );
  serverApi.routerHook.addRoute(
    "/about-gamevault",
    () => {
      return <About serverAPI={serverApi} />
    },
    {
      exact: true,
    }
  );
  serverApi.routerHook.addRoute(
    "/gamevault-downloads",
    () => {
      return <DownloadsPage />
    },
    {
      exact: true,
    }
  );
  // Initialize install queue with server API and reconnect to any in-progress downloads
  installQueue.setServerAPI(serverApi);
  installQueue.reconnect();




  return {
    title: <div className={staticClasses.Title}>GameVault</div>,
    content: <Content serverAPI={serverApi} initActionSet="init" initAction="InitActions" />,
    icon: <FaBoxOpen />,
    onDismount() {
      serverApi.routerHook.removeRoute("/gamevault-content/:initActionSet/:initAction");
      serverApi.routerHook.removeRoute("/about-gamevault");
      serverApi.routerHook.removeRoute("/gamevault-downloads");
      unregister.unregister();
    },
  };
});
