import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import * as THREE from "three";
import { EffectComposer, RenderPass } from "postprocessing";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { trinitron } from "./tvs";

// three scene
let camera, composer, renderer, scene;
// video
let video, videoMaterial, videoTexture;
// state
let videoIsPlaying = false;
// models
let marbleColumn, tvModel, tvScreenModel;
// controls
let orbitControls;
//
let T = { currentTime: 0, status: "stopped", ticking: false };

function animation(time) {
  if (video && video.readyState === video.HAVE_ENOUGH_DATA) {
    videoTexture.needsUpdate = true;
    if (videoMaterial) videoMaterial.uniforms.time.value += 0.1;
  }

  renderer.clear();
  composer.render();
}

function animate() {
  requestAnimationFrame(animation);
  orbitControls.update();
}

async function init() {
  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.shadowMap.autoUpdate = true;
  renderer.toneMapping = THREE.LinearToneMapping;
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

  document.getElementById("three").appendChild(renderer.domElement);

  camera = new THREE.PerspectiveCamera(
    70,
    window.innerWidth / window.innerHeight,
    10,
    1000
  );
  camera.position.set(-10, 42, 76);

  scene = new THREE.Scene();

  setupLighting();
  setupControls();

  const backgroundTexture = new THREE.TextureLoader().load(
    "https://cdn.dexterslab.sh/audiuslive/assets/images/vroom.webp"
  );
  backgroundTexture.crossOrigin = "anonymous";

  const geometry = new THREE.BoxGeometry(300, 300, 300);
  const material = new THREE.MeshBasicMaterial({ map: backgroundTexture });
  const backgroundBox = new THREE.Mesh(geometry, material);
  backgroundBox.material.side = THREE.BackSide;
  backgroundBox.scale.setX(2);
  backgroundBox.scale.setZ(1.8);
  scene.add(backgroundBox);

  const tvSetup = await trinitron();

  tvModel = tvSetup.tv;
  tvScreenModel = tvSetup.screen;
  videoMesh = tvSetup.mesh;
  video = tvSetup.video;
  videoMaterial = tvSetup.material;
  videoTexture = tvSetup.texture;

  scene.add(tvModel);
  scene.add(videoMesh);
  scene.add(tvScreenModel);

  const tvScreenBoundingBox = new THREE.Box3().setFromObject(tvScreenModel);
  const tvScreenSize = tvScreenBoundingBox.getSize(new THREE.Vector3());

  const videoMeshBoundingBox = new THREE.Box3().setFromObject(videoMesh);
  const videoMeshPosition = new THREE.Vector3();
  videoMeshBoundingBox.getCenter(videoMeshPosition);

  const blackBars = new THREE.Mesh(
    new THREE.PlaneGeometry(tvScreenSize.x, tvScreenSize.y + 6),
    new THREE.MeshBasicMaterial({ color: 0x000000 })
  );

  const tvScreenCenter = new THREE.Vector3();
  tvScreenBoundingBox.getCenter(tvScreenCenter);

  blackBars.position.copy(tvScreenCenter);
  blackBars.position.z = videoMeshPosition.z - 0.01;

  scene.add(blackBars);

  let modelLoader = new GLTFLoader();

  const marbleColumnData = await modelLoader.loadAsync(
    "https://cdn.dexterslab.sh/audiuslive/assets/models/marble_pillar.glb"
  );

  marbleColumn = marbleColumnData.scene.children[0];
  marbleColumn.castShadow = true;
  marbleColumn.receiveShadow = true;

  marbleColumn.scale.multiplyScalar(2.8);
  marbleColumn.scale.x *= 1.4;

  scene.add(marbleColumn);

  setupEventListeners();
  setupPostprocessing();
  renderer.setAnimationLoop(animate);
}

function setupLighting() {
  const dirLight = new THREE.DirectionalLight("#ffffff", 1.5);
  dirLight.castShadow = true;
  dirLight.shadow.camera.far = 20;
  dirLight.shadow.mapSize.set(2048, 2048);
  dirLight.shadow.normalBias = 0.05;
  dirLight.position.set(-1.5, 7, 3);
  scene.add(dirLight);

  const ambientLight = new THREE.AmbientLight("#ffffff", 0.7);
  scene.add(ambientLight);
  scene.add(dirLight);
}

function setupControls() {
  orbitControls = new OrbitControls(camera, renderer.domElement);
  orbitControls.enableDamping = true;
  orbitControls.enablePan = false;
  orbitControls.dampingFactor = 0.08;
  orbitControls.minDistance = 56;
  orbitControls.maxDistance = 223;
  orbitControls.maxPolarAngle = 4.75 * (Math.PI / 7);
  orbitControls.minPolarAngle = Math.PI / 4;
}

function setupPostprocessing() {
  renderer.autoClear = false;
  const renderModel = new RenderPass(scene, camera);
  composer = new EffectComposer(renderer);
  composer.addPass(renderModel);
}

function setupEventListeners() {
  window.addEventListener("click", playVideo, false);
  window.addEventListener(
    "resize",
    function () {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
      renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    },
    false
  );
}

function setupClock() {
  let csrfToken = document
    .querySelector("meta[name='csrf-token']")
    .getAttribute("content");
  let liveSocket = new LiveSocket("/live", Socket, {
    params: { _csrf_token: csrfToken },
  });

  const stop = (interval) => {
    clearInterval(interval);
    T.ticking = false;
    video.pause();
  };

  T = { ticking: false };
  window.addEventListener("phx:clockUpdated", (e) => {
    T.currentTime = e.detail.time;
    T.status = e.detail.status;
    if (!videoIsPlaying) video.currentTime = T.currentTime;

    if (T.status == "running" && !T.ticking) {
      T.ticking = true;
      T.interval = setInterval(function () {}, 1000);
    }

    if (T.status == "stopped") {
      stop(T.interval);
    }
  });

  window.addEventListener("phx:videoUpdated", (e) => {
    const videoUrl = e.detail.video_url;
    video.src = videoUrl;
    video.load();
  });

  liveSocket.connect();
  liveSocket.enableDebug();
  window.liveSocket = liveSocket;
}

function playVideo() {
  if (videoIsPlaying) return;
  if (T.status == "running") video.play();
  videoIsPlaying = true;
}

(async () => {
  await init();
  setupClock();
  setTimeout(() => {
    const loader = document.getElementById("loader");
    loader.classList.toggle("opacity-0");
    loader.classList.toggle("opacity-100");
    loader.classList.toggle("pointer-events-none");
  }, 1200);
})();
