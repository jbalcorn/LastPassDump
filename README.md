# LastPassDump
Quick and dirty code to decode your LastPass vault.

 Get your vault by using the technique Wladimir Palant provided, and supplied in the Security Now! Show notes at https://www.grc.com/sn/SN-904-Notes.pdf
 
 ```
 fetch("https://lastpass.com/getaccts.php", {method: "POST"}) 
         .then(response => response.text()) 
         .then(text => console.log(text.replace(/>/g, ">\n")));
 ```
 
 Then run this powershell to get a text output of your accounts in the vault and any decodeable values.
 
 It's really quick and dirty right now, I'm working on making it cleaner.
