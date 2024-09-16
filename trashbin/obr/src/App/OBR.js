import OBR from "@owlbear-rodeo/sdk";

OBR.onReady = OBR.onReady.bind(OBR);
OBR.scene.isReady = OBR.scene.isReady.bind(OBR.scene);
OBR.scene.onReadyChange = OBR.scene.onReadyChange.bind(OBR.scene);
OBR.scene.getMetadata = OBR.scene.getMetadata.bind(OBR.scene);
OBR.scene.setMetadata = OBR.scene.setMetadata.bind(OBR.scene);
OBR.scene.onMetadataChange = OBR.scene.onMetadataChange.bind(OBR.scene);
OBR.scene.items.getItems = OBR.scene.items.getItems.bind(OBR.scene.items);
OBR.scene.items.onChange = OBR.scene.items.onChange.bind(OBR.scene.items);
OBR.scene.items.updateItems = OBR.scene.items.updateItems.bind(OBR.scene.items);
OBR.broadcast.sendMessage = OBR.broadcast.sendMessage.bind(OBR.broadcast);
OBR.broadcast.onMessage = OBR.broadcast.onMessage.bind(OBR.broadcast);
OBR.player.getMetadata = OBR.player.getMetadata.bind(OBR.player);
OBR.player.select = OBR.player.select.bind(OBR.player);

export const _undefined = undefined;

export const obr = OBR;
export const ready = new Promise((resolve) => {
  OBR.onReady(resolve);
});

export function getMetadata(md) {
  return function _getMetadata(key) {
    const v = md[key];
    return v == null ? null : v;
  };
}

export function setMetadata(md) {
  return function _setMetadata(key) {
    return function _setMetadata(value) {
      return { ...md, [key]: value };
    };
  };
}

export function unsetMetadata(md) {
  return function _unsetMetadata(key) {
    return { ...md, [key]: undefined };
  };
}

export function unsetMetadataKeyFilter(key) {
  return { key: ["metadata", key], operator: "==", value: undefined };
}

export function setMetadataKeyFilter(key) {
  return { key: ["metadata", key], operator: "!=", value: undefined };
}

export function mutation(cb) {
  return function mutate(v) {
    const result = cb(v);
    if (Array.isArray(v)) {
      v.splice(0, v.length, ...result);
    } else {
      Object.assign(v, result);
    }
  };
}

export function _updateItems(items) {
  return function (mapper) {
    return OBR.scene.items.updateItems(items, (draft) => {
      for (const item of draft) {
        const modified = mapper(item);
        Object.assign(item, modified);
      }
    });
  };
}

export const emptyMetadata = {};
export function asJson(md) {
  return md;
}
