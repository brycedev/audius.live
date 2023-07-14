import { bundle } from "@remotion/bundler";
import { renderMedia, selectComposition } from "@remotion/renderer";
import path from "path";
 
// The composition you want to render
const compositionId = "Scene";
 
// You only have to create a bundle once, and you may reuse it
const bundleLocation = await bundle({
  entryPoint: path.resolve("./src/index.ts"),
  // If you have a Webpack override, make sure to add it here
  webpackOverride: (config) => config,
});

const composition = await selectComposition({
  serveUrl: bundleLocation,
  id: compositionId,
  chromiumOptions: {
    gl: "swangle"
  }
});
 
// Render the video
await renderMedia({
  composition,
  serveUrl: bundleLocation,
  codec: "h264",
  outputLocation: `videoout`,
  chromiumOptions: {
    gl: "swangle"
  }
  
});
 
console.log("Render done!");