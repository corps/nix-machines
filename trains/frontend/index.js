function main() {
  // See for configuration options: https://github.com/purescript/spago#get-started-from-scratch-with-parcel-frontend-projects
  require("../output/Main").main();
}

// HMR setup. For more info see: https://parceljs.org/hmr.html
if (module.hot) {
  module.hot.accept(function () {
    console.log("Reloaded, running main again");
    main();
  });
}

console.log("Starting app");

main();
