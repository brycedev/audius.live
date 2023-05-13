import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import * as THREE from "three";

function generateVideoMesh(tvScreen) {
  let video = document.createElement("video");
  // video.src = "https://cdn.dexterslab.sh/street.mp4";
  // video.src = "https://cdn.dexterslab.sh/waves.mp4";
  video.src =
    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
  video.crossOrigin = "anonymous";
  video.loop = true;
  video.load();
  video.addEventListener("play", function () {
    this.currentTime = 0;
  });

  let videoTexture = new THREE.VideoTexture(video);
  videoTexture.crossOrigin = "anonymous";

  let videoMaterial = new THREE.ShaderMaterial({
    uniforms: {
      tDiffuse: { value: videoTexture },
      time: { value: 0.0 },
      distortion: { value: 3.0 },
      distortion2: { value: 4.0 },
      speed: { value: 0.2 },
      rollSpeed: { value: 0.01 },
    },
    vertexShader: `
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
    }
    `,
    fragmentShader: [
      "uniform sampler2D tDiffuse;",
      "uniform float time;",
      "uniform float distortion;",
      "uniform float distortion2;",
      "uniform float speed;",
      "uniform float rollSpeed;",
      "varying vec2 vUv;",

      // Start Ashima 2D Simplex Noise

      "vec3 mod289(vec3 x) {",
      "  return x - floor(x * (1.0 / 289.0)) * 289.0;",
      "}",

      "vec2 mod289(vec2 x) {",
      "  return x - floor(x * (1.0 / 289.0)) * 289.0;",
      "}",

      "vec3 permute(vec3 x) {",
      "  return mod289(((x*34.0)+1.0)*x);",
      "}",

      "float snoise(vec2 v)",
      "  {",
      "  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0",
      "                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)",
      "                     -0.577350269189626,  // -1.0 + 2.0 * C.x",
      "                      0.024390243902439); // 1.0 / 41.0",
      "  vec2 i  = floor(v + dot(v, C.yy) );",
      "  vec2 x0 = v -   i + dot(i, C.xx);",

      "  vec2 i1;",
      "  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);",
      "  vec4 x12 = x0.xyxy + C.xxzz;",
      " x12.xy -= i1;",

      "  i = mod289(i); // Avoid truncation effects in permutation",
      "  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))",
      "		+ i.x + vec3(0.0, i1.x, 1.0 ));",

      "  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);",
      "  m = m*m ;",
      "  m = m*m ;",

      "  vec3 x = 2.0 * fract(p * C.www) - 1.0;",
      "  vec3 h = abs(x) - 0.5;",
      "  vec3 ox = floor(x + 0.5);",
      "  vec3 a0 = x - ox;",

      "  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );",

      "  vec3 g;",
      "  g.x  = a0.x  * x0.x  + h.x  * x0.y;",
      "  g.yz = a0.yz * x12.xz + h.yz * x12.yw;",
      "  return 130.0 * dot(m, g);",
      "}",

      // End Ashima 2D Simplex Noise

      "void main() {",

      "vec2 p = vUv;",
      "float ty = time*speed;",
      "float yt = p.y - ty;",
      //smooth distortion
      "float offset = snoise(vec2(yt*3.0,0.0))*0.2;",
      // boost distortion
      "offset = offset*distortion * offset*distortion * offset;",
      //add fine grain distortion
      "offset += snoise(vec2(yt*50.0,0.0))*distortion2*0.001;",
      //combine distortion on X with roll on Y
      "gl_FragColor = texture2D(tDiffuse,  vec2(fract(p.x + offset),fract(p.y-time*rollSpeed) ));",

      "}",
    ].join("\n"),
  });

  const videoMesh = new THREE.Mesh(
    new THREE.PlaneGeometry(1280, 720),
    videoMaterial
  );

  const screenBoundingBox = new THREE.Box3().setFromObject(tvScreen);
  const screenPosition = screenBoundingBox.getCenter(new THREE.Vector3());
  const screenSize = screenBoundingBox.getSize(new THREE.Vector3());

  const scaleRatio = screenSize.x / 1280;

  videoMesh.scale.x = scaleRatio;
  videoMesh.scale.y = scaleRatio;

  videoMesh.position.copy(screenPosition);
  videoMesh.position.z -= 1.75;

  return {
    video,
    mesh: videoMesh,
    material: videoMaterial,
    texture: videoTexture,
  };
}

export async function trinitron() {
  const modelLoader = new GLTFLoader();

  const tvModelData = await modelLoader.loadAsync(
    "https://cdn.dexterslab.sh/sony_trinitron_body.glb"
  );

  tvModel = tvModelData.scene;
  tvModel.castShadow = true;
  tvModel.receiveShadow = true;

  const yPosition = 15.7;
  const zPosition = 5.5;

  let tvBoundingBox = new THREE.Box3().setFromObject(tvModel);
  let tvCenter = tvBoundingBox.getCenter(new THREE.Vector3());
  let tvSize = tvBoundingBox.getSize(new THREE.Vector3());

  let maxAxis = Math.max(tvSize.x, tvSize.y, tvSize.z);
  tvModel.scale.multiplyScalar(41.7 / maxAxis);
  tvBoundingBox.setFromObject(tvModel);
  tvBoundingBox.getCenter(tvCenter);
  tvBoundingBox.getSize(tvSize);
  tvModel.position.copy(tvCenter).multiplyScalar(-1);

  tvModel.position.y = yPosition;
  tvModel.position.z = zPosition;
  tvModel.rotateY(Math.PI);

  const tvScreenData = await modelLoader.loadAsync(
    "https://cdn.dexterslab.sh/sony_trinitron_screen.glb"
  );

  const tvScreen = tvScreenData.scene;
  tvScreen.castShadow = true;
  tvScreen.receiveShadow = true;

  tvScreen.scale.multiplyScalar(41.7 / maxAxis);
  tvScreen.position.copy(tvCenter).multiplyScalar(-1);
  tvScreen.position.y = yPosition;
  tvScreen.position.z = zPosition;
  tvScreen.rotateY(Math.PI);

  tvScreen.traverse(function (child) {
    if (child.isMesh === true) {
      child.material = new THREE.MeshPhysicalMaterial({
        metalness: 0.8,
        thickness: 0.12,
        roughness: 0.1,
        transmission: 1,
        reflectivity: 1,
      });
      child.material.needsUpdate = true;
    }
  });

  const videoMeshData = generateVideoMesh(tvScreen);

  return {
    tv: tvModel,
    screen: tvScreen,
    mesh: videoMeshData.mesh,
    video: videoMeshData.video,
    texture: videoMeshData.texture,
    material: videoMeshData.material,
  };
}

export async function magnavox(THREE) {
  const modelLoader = new GLTFLoader();

  const tvModelData = await modelLoader.loadAsync(
    "https://cdn.dexterslab.sh/magnavox_body.glb"
  );

  tvModel = tvModelData.scene;
  tvModel.castShadow = true;
  tvModel.receiveShadow = true;

  let bbox = new THREE.Box3().setFromObject(tvModel);
  let cent = bbox.getCenter(new THREE.Vector3());
  let size = bbox.getSize(new THREE.Vector3());

  let maxAxis = Math.max(size.x, size.y, size.z);
  tvModel.scale.multiplyScalar(41.7 / maxAxis);
  bbox.setFromObject(tvModel);
  bbox.getCenter(cent);
  bbox.getSize(size);
  tvModel.position.copy(cent).multiplyScalar(-1);
  tvModel.position.y = 0;

  const tvSize = new THREE.Vector3();
  const tvBoundingBox = new THREE.Box3().setFromObject(tvModel);
  tvBoundingBox.getSize(tvSize);

  const videoMeshData = generateVideoMesh(tvSize, tvModel.position);

  return {
    model: tvModel,
    mesh: videoMeshData.mesh,
    video: videoMeshData.video,
    texture: videoMeshData.texture,
    material: videoMeshData.material,
  };
}
