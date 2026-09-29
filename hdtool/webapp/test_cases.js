// edge cases for core.js (run: node test_cases.js <zip> <userdisk> <font> <sysdir_ascii>)
const fs=require('fs'),zlib=require('zlib'); require('./core.js');
const [zipf,userf,fontf,sysdir]=process.argv.slice(2);
const A=JSON.parse(fs.readFileSync(__dirname+'/assets.json','utf8'));
const inflate=async raw=>new Uint8Array(zlib.inflateRawSync(Buffer.from(raw)));
const rd=p=>new Uint8Array(fs.readFileSync(p));
const base=async()=>{const it=[{name:'a.zip',data:rd(zipf)},{name:'userdisk.DSK',data:rd(userf)},{name:'KANJI.rom',data:rd(fontf)}];for(const n of fs.readdirSync(sysdir))it.push({name:n,data:rd(sysdir+'/'+n)});return ICITY.classify(it,inflate);};
let fails=0; const ok=(c,m)=>{console.log((c?'PASS ':'FAIL ')+m); if(!c) fails++;};
(async()=>{
  let cls=await base();
  // 1 no font
  let r=ICITY.build({assets:A,cls,useFont:false,readme:false,autoexec:false});
  let fl=ICITY.flatten(r.rootFiles,'');
  ok(!r.applied.includes('G1') && !fl.some(f=>f.path==='ICITY/FONT.BIN'),'font off: no G1 patch, no FONT.BIN');
  ok(r.applied.join()==='L1,L4,K1,INIT,K2,M1,M2,M3,P1,P2,P3,P4,P5,P6','font off: other patches applied (incl. save-list paging P1-P6)');
  // 2 font on
  r=ICITY.build({assets:A,cls,useFont:true}); fl=ICITY.flatten(r.rootFiles,'');
  ok(r.applied.includes('G1') && fl.some(f=>f.path==='ICITY/FONT.BIN'),'font on: G1 + FONT.BIN');
  // 3 blank saves
  r=ICITY.build({assets:A,cls,useFont:true,keepSaves:false}); fl=ICITY.flatten(r.rootFiles,'');
  const sv=fl.find(f=>f.path==='ICITY/SAVE/DU_0578.DAT'); ok(sv && sv.data.every(b=>b===0),'blank saves: DU_0578.DAT is all zero'); ok(sv && sv.data.length===98304,'save file holds 96 slots (96KB)');
  // 4 missing disk
  let c2=JSON.parse(JSON.stringify({}));cls=await base(); delete cls.disks[5];
  try{ICITY.build({assets:A,cls});ok(false,'missing disk should throw');}catch(e){ok(/disk 5/.test(e.message),'missing disk 5 -> "'+e.message+'"');}
  // 5 wrong release (patch bytes differ)
  cls=await base(); cls.disks[1]={name:'x',data:cls.disks[1].data.slice()}; cls.disks[1].data[14*512+0x11]^=0xFF;
  try{ICITY.build({assets:A,cls,useFont:false});ok(false,'mismatch should throw');}catch(e){ok(/patch L1/.test(e.message),'patched bytes differ -> "'+e.message+'"');}
  // 6 wrong chunk layout (file table changed)
  cls=await base(); cls.disks[3]={name:'x',data:cls.disks[3].data.slice()}; cls.disks[3].data[11*512+2*14+0]=0x20; cls.disks[3].data[11*512+2*14+1]=5; /* file 14 (scenario): start 0x20, 5 sectors -> new chunk boundaries */
  try{ICITY.build({assets:A,cls,useFont:false});ok(false,'layout should throw');}catch(e){ok(/disk 3/.test(e.message),'layout differs -> "'+e.message+'"');}
  // 7 Nextor-only DOS files and image size limits
  cls=await base(); cls.dos={'NEXTOR.SYS':new Uint8Array(4467),'COMMAND2.COM':new Uint8Array(1000)};
  r=ICITY.build({assets:A,cls,useFont:true,autoexec:true,readme:true}); const im=ICITY.makeImage(r.rootFiles,r.boot,'X',new Date());
  ok(im.used<im.clusters,'nextor files fit ('+im.used+'/'+im.clusters+' clusters)');
  // 8 no dos files still builds
  cls=await base(); cls.dos={}; r=ICITY.build({assets:A,cls,useFont:true}); ok(r.rootFiles.some(f=>f.name==='ICITY.COM'),'no DOS files: still builds (warning only)');
  // 9 disk identification is by label, not file name
  const it=[]; const z=await ICITY.classify([{name:'a.zip',data:rd(zipf)}],inflate); for(const n of [3,1,2,8,7,6,5,4]) it.push({name:'weird'+n+'.bin',data:z.disks[n].data}); const c3=await ICITY.classify(it,inflate); ok(Object.keys(c3.disks).sort().join('')==='12345678','disks recognized by IPROJ label regardless of file names');
  console.log(fails?fails+' FAILED':'all passed'); process.exit(fails?1:0);
})();
