// components/VerifyPanel.tsx
'use client';

import React, { useRef, useState } from 'react';
import Dropzone from '../Dropzone';
import * as UTIF from 'utif';

interface Props {
  onVerify: (file: File) => Promise<{
    match: boolean;
    name: string;
    passport_no: string;
    score: number;
    user_id: string;
  }>;
  setError: (err: string | null) => void;
}

export default function VerifyPanel({ onVerify, setError }: Props) {
  const [file, setFile] = useState<File | null>(null);
  const [result, setResult] = useState<null | {
    match: boolean;
    name: string;
    passport_no: string;
    score: number;
    user_id: string;
  }>(null);

  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  const renderTiff = (file: File) => {
    const reader = new FileReader();
    reader.onload = () => {
      try {
        const buffer = new Uint8Array(reader.result as ArrayBuffer);
        const ifds = UTIF.decode(buffer);
        if (ifds.length === 0) throw new Error('No IFD found');
        UTIF.decodeImage(buffer, ifds[0]);
        const rgba = UTIF.toRGBA8(ifds[0]);
        const canvas = canvasRef.current!;
        const ctx = canvas.getContext('2d')!;
        const imgData = ctx.createImageData(ifds[0].width, ifds[0].height);
        imgData.data.set(rgba);
        canvas.width = ifds[0].width;
        canvas.height = ifds[0].height;
        ctx.putImageData(imgData, 0, 0);
      } catch (err: any) {
        setError(err.message || 'Failed to render TIFF');
      }
    };
    reader.readAsArrayBuffer(file);
  };

  const handleUpload = (file: File | null) => {
    setFile(file);
    setResult(null);
    if (file && canvasRef.current) {
      renderTiff(file);
    }
  };

  const handleVerify = async () => {
    if (!file) {
      setError('Please upload a fingerprint');
      return;
    }
    try {
      const data = await onVerify(file);
      setResult(data);
    } catch (err: any) {
      setError(err.message || 'Verification failed');
    }
  };

  return (
    <div className="bg-sky-800 p-6 rounded-lg shadow-lg">
      <h2 className="text-xl font-bold mb-4">2️⃣ Verify Fingerprint</h2>
      <Dropzone label="Upload Fingerprint (.tif)" accept=".tif,.tiff" onDrop={handleUpload} />
      {file && <canvas ref={canvasRef} className="w-full mt-4 border rounded shadow" />}
      <button onClick={handleVerify} className="w-full mt-4 py-2 bg-sky-600 hover:bg-sky-500 rounded font-semibold">
        Verify
      </button>

      {result && (
        <div className={`mt-4 p-4 rounded ${result.match ? 'bg-green-800' : 'bg-red-800'}`}>
          {result.match ? '✅ Match Found' : '❌ No Match'}
          <p className="text-sm mt-2">Name: {result.name}</p>
          <p className="text-sm">Passport: {result.passport_no}</p>
          <p className="text-sm">Score: {result.score}</p>
          <p className="text-sm">User ID: {result.user_id}</p>
        </div>
      )}
    </div>
  );
}
