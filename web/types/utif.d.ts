// web/types/utif.d.ts
declare module 'utif' {
    export function decode(buffer: Uint8Array): any[];
    export function decodeImage(buffer: Uint8Array, ifd: any): void;
    export function toRGBA8(ifd: any): Uint8Array;
  }
  