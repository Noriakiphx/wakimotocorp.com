'use strict';
(function(){
const req=document.getElementById('request-link');
const email=document.getElementById('email');
const quantity=document.getElementById('quantity');
const type=document.getElementById('type');
const pay=document.getElementById('square-pay');
const status=document.getElementById('sales-status');
function refresh(){
const subject='Auriteq Flow 初回入荷案内希望';
const body='Auriteq Flowの初回入荷案内を希望します。\n\n希望台数: '+quantity.value+'台\n区分: '+type.value+'\n返信先: '+email.value+'\n\n※これは購入希望の問い合わせであり、注文・決済ではありません。';
req.href='mailto:wakimoto@wakimotocorp.com?subject='+encodeURIComponent(subject)+'&body='+encodeURIComponent(body);
}
[email,quantity,type].forEach(e=>e.addEventListener('input',refresh));refresh();
// Square Checkout is only enabled after an actual merchant-created payment link
// and Japanese retail price / stock are confirmed. No API keys or card data in client code.
const squarePaymentUrl='';
const domesticSaleConfirmed=false;
if(domesticSaleConfirmed&&/^https:\/\/(square\.link|checkout\.square\.site|squareup\.com)\//.test(squarePaymentUrl)){
  pay.disabled=false;pay.textContent='Squareで安全に決済する ↗';
  status.textContent='決済受付中';
  pay.addEventListener('click',()=>{window.location.href=squarePaymentUrl});
}
})();