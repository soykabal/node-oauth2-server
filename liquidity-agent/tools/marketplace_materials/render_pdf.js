const { chromium } = require(require('child_process').execSync('npm root -g').toString().trim() + '/playwright');
const path=require('path');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage();
for (const [f,out,opt] of [['deck_marketplace.html','Kabal_Digital_Marketplace_Liquidity_Partners_EN.pdf',{width:'1280px',height:'720px'}],['onepager_marketplace.html','Kabal_Digital_Marketplace_One_Pager_EN.pdf',{format:'Letter'}]]){
  await p.goto('file://'+path.resolve(__dirname,f)); await p.evaluate(()=>document.fonts.ready); await p.waitForTimeout(300);
  await p.pdf(Object.assign({path:out,printBackground:true,preferCSSPageSize:true,margin:{top:0,bottom:0,left:0,right:0}},opt));
  console.log(out, require('fs').statSync(out).size);
}
await b.close();})();
