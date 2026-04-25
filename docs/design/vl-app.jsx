function VLApp(){
  return (
    <DesignCanvas>
      <DCSection id="vl" title="Voice Ledger — iOS MVP" subtitle="Chat-style ledger · voice + text · auto-parsed by AI">
        <DCArtboard id="stream" label="① Record stream" width={402} height={874}>
          <IOSDevice dark={true}><VLStream/></IOSDevice>
        </DCArtboard>
        <DCArtboard id="edit" label="② Edit transaction" width={402} height={874}>
          <IOSDevice dark={true}><VLEdit/></IOSDevice>
        </DCArtboard>
        <DCArtboard id="stats" label="③ Stats" width={402} height={874}>
          <IOSDevice dark={true}><VLStats/></IOSDevice>
        </DCArtboard>
        <DCArtboard id="settings" label="④ Settings · AI provider" width={402} height={874}>
          <IOSDevice dark={true}><VLSettings/></IOSDevice>
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

const vlRoot = ReactDOM.createRoot(document.getElementById('app'));
vlRoot.render(<VLApp/>);

const vlCss = document.createElement('style');
vlCss.textContent = `
  @keyframes vlPulse { 0%,100% { opacity:1; transform:scale(1); } 50% { opacity:0.4; transform:scale(0.85); } }
  @keyframes vlBar { 0%,100% { transform:scaleY(0.5); } 50% { transform:scaleY(1.4); } }
  body { background: #0E0E12; }
`;
document.head.appendChild(vlCss);
