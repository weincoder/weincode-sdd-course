import { extend } from 'angular-three';
import {
  AmbientLight,
  BoxGeometry,
  BufferGeometry,
  ConeGeometry,
  CylinderGeometry,
  DirectionalLight,
  DodecahedronGeometry,
  FogExp2,
  Group,
  HemisphereLight,
  InstancedMesh,
  Mesh,
  MeshBasicMaterial,
  MeshPhysicalMaterial,
  MeshStandardMaterial,
  Object3D,
  PerspectiveCamera,
  PlaneGeometry,
  PointLight,
  Points,
  PointsMaterial,
  RingGeometry,
  SphereGeometry,
  TorusGeometry,
} from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

let isCatalogueRegistered = false;

export function registerNgtCatalogue(): void {
  if (isCatalogueRegistered) {
    return;
  }
  extend({
    Mesh,
    Group,
    Object3D,
    InstancedMesh,
    Points,
    DirectionalLight,
    HemisphereLight,
    AmbientLight,
    PointLight,
    MeshStandardMaterial,
    MeshPhysicalMaterial,
    MeshBasicMaterial,
    PointsMaterial,
    BufferGeometry,
    PlaneGeometry,
    CylinderGeometry,
    ConeGeometry,
    SphereGeometry,
    RingGeometry,
    TorusGeometry,
    BoxGeometry,
    DodecahedronGeometry,
    PerspectiveCamera,
    FogExp2,
    OrbitControls,
  });
  isCatalogueRegistered = true;
}

registerNgtCatalogue();
