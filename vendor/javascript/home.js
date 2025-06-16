// home@2.0.0 downloaded from https://ga.jspm.io/npm:home@2.0.0/index.js

import o from"path";import e from"os";var r={};const{resolve:t}=o;const m=e.homedir();function home(){return m}const resolveHome=o=>"~"===o?m:~o.indexOf("~/")?m+o.slice(1):o;home.resolve=(...o)=>t(...o.map(resolveHome));r=home;var n=r;export default n;

