'use client';

import React, { useRef } from 'react';
import Dropzone from '../Dropzone';
import * as UTIF from 'utif';

interface Props {
  onRegister: () => void;
  setError: (err: string | null) => void;
  passportFile: File | null;
  fingerprintFile: File | null;
  setPassportFile: (file: File | null) => void;
  setFingerprintFile: (file: File | null) => void;
  extractedName: string;
  extractedPassportNo: string;
}

export default function RegisterPanel({
  onRegister,
  setError,
  passportFile,
  fingerprintFile,
  setPassportFile,
  setFingerprintFile,
  extractedName,
  extractedPassportNo,
}: Props) {
  const fingerprintCanvasRef = useRef<HTMLCanvasElement | null>(null);

  const renderTiff = (file: File) => {
    const reader = new FileReader();
    reader.onload = () => {
      try {
        const buffer = new Uint8Array(reader.result as ArrayBuffer);
        const ifds = UTIF.decode(buffer);
        if (ifds.length === 0) throw new Error('No IFD found in TIFF');
        UTIF.decodeImage(buffer, ifds[0]);

        const rgba = UTIF.toRGBA8(ifds[0]);
        const canvas = fingerprintCanvasRef.current;
        if (!canvas) throw new Error('Canvas not found');
        const ctx = canvas.getContext('2d');
        if (!ctx) throw new Error('Canvas context is null');

        canvas.width = ifds[0].width;
        canvas.height = ifds[0].height;
        const imgData = ctx.createImageData(ifds[0].width, ifds[0].height);
        imgData.data.set(rgba);
        ctx.putImageData(imgData, 0, 0);
      } catch (err: any) {
        console.error('❌ Failed to render TIFF:', err);
        setError(err.message || 'Failed to render TIFF');
      }
    };

    reader.onerror = () => {
      console.error('❌ FileReader failed');
      setError('Failed to read fingerprint file');
    };

    reader.readAsArrayBuffer(file);
  };

  const handlePassportUpload = (file: File | null) => {
    setPassportFile(file);
  };

  const handleFingerprintUpload = (file: File | null) => {
    setFingerprintFile(file);
    if (file) renderTiff(file);
  };

  return (
    <div className="bg-sky-800 p-6 rounded-lg shadow-lg">
      <h2 className="text-xl font-bold mb-4">Register Traveler</h2>

      <Dropzone label="Upload Passport Image" accept="image/*" onDrop={handlePassportUpload} />
      <div className="my-4" />
      <Dropzone label="Upload Fingerprint (.tif)" accept=".tif,.tiff" onDrop={handleFingerprintUpload} />

      {fingerprintFile && (
        <canvas ref={fingerprintCanvasRef} className="w-full mt-4 border rounded shadow" />
      )}

      <div className="mt-4 text-sm space-y-1">
        <p>Name: <strong>{extractedName || '—'}</strong></p>
        <p>Passport: <strong>{extractedPassportNo || '—'}</strong></p>
      </div>

      <button
        onClick={onRegister}
        className="w-full mt-4 py-2 bg-green-600 hover:bg-green-500 rounded font-semibold"
      >
        Register
      </button>
    </div>
  );
}
