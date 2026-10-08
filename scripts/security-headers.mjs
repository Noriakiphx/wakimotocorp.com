import {readFile,writeFile,readdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
const hashes=new Set();
for(const name of await readdir('.')){
 if(!name.endsWith('.html'))continue;
 const html=await readFile(name,'utf8');
 for(const match of html.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script>/gi)){
  if(/\bsrc\s*=/i.test(match[1]))continue;
  hashes.add("'sha256-"+createHash('sha256').update(match[2]).digest('base64')+"'");
 }
}
const csp="default-src 'self'; script-src 'self' "+[...hashes].join(' ')+"; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'self'; upgrade-insecure-requests";
await writeFile('_headers','/*\n  Content-Security-Policy: '+csp+'\n  Strict-Transport-Security: max-age=31536000\n  X-Permitted-Cross-Domain-Policies: none\n');
console.log('Security headers generated for '+hashes.size+' inline scripts.');
