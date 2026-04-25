// iOS App entry — three iPhone frames on a design canvas
function IOSApp(){
  return (
    <DesignCanvas>
      <DCSection id="ios" title="iOS Chat — PocketMind">
        <DCArtboard id="list" label="Chats" width={402} height={874}>
          <IOSDevice dark={true}><ScreenChats/></IOSDevice>
        </DCArtboard>
        <DCArtboard id="convo" label="Conversation" width={402} height={874}>
          <IOSDevice dark={true}><ScreenConvo/></IOSDevice>
        </DCArtboard>
        <DCArtboard id="info" label="Contact info" width={402} height={874}>
          <IOSDevice dark={true}><ScreenInfo/></IOSDevice>
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

const iosRoot = ReactDOM.createRoot(document.getElementById('app'));
iosRoot.render(<IOSApp/>);

// Animations
const iosCss = document.createElement('style');
iosCss.textContent = `
  @keyframes iosTyping {
    0%, 80%, 100% { opacity: 0.3; transform: scale(0.85); }
    40% { opacity: 1; transform: scale(1.1); }
  }
  body { background: #0E0E12; }
`;
document.head.appendChild(iosCss);
