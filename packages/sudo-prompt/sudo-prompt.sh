#! @bash@/bin/bash

PATH=@node@/bin/:$PATH
NODE_PATH=@sudoPrompt@/lib/node_modules:$NODE_PATH

exec node << END
var sudo = require("sudo-prompt");

sudo.exec('', {}, function (err, stdout, stderr) {

});
END
