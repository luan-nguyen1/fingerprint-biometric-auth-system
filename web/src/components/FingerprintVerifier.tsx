'use client';

import { useState, useRef, useEffect } from 'react';
import * as UTIF from 'utif';

// Define the shape of the response from the verify-fingerprint API
interface VerifyResponse {
  match: boolean;
  score: number;
  user_id: string;
}

const FingerprintVerifier = () => {
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [result, setResult] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const previewCanvasRef = useRef<HTMLCanvasElement | null>(null);

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      setSelectedFile(file);
      setResult(null);
    } else {
      setSelectedFile(null);
      setResult(null);
    }
  };

  useEffect(() => {
    if (!selectedFile || !previewCanvasRef.current) return;

    const reader = new FileReader();
    reader.onload = () => {
      const buffer = new Uint8Array(reader.result as ArrayBuffer);
      const ifds = UTIF.decode(buffer);
      UTIF.decodeImage(buffer, ifds[0]);
      const rgba = UTIF.toRGBA8(ifds[0]);

      const canvas = previewCanvasRef.current!;
      const ctx = canvas.getContext('2d')!;
      const imgData = ctx.createImageData(ifds[0].width, ifds[0].height);
      imgData.data.set(rgba);
      canvas.width = ifds[0].width;
      canvas.height = ifds[0].height;
      ctx.putImageData(imgData, 0, 0);
    };

    reader.readAsArrayBuffer(selectedFile);
  }, [selectedFile]);

  const readFileAsDataURL = (file: File): Promise<string> => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result as string);
      reader.onerror = () => reject(new Error('Failed to read file'));
      reader.readAsDataURL(file);
    });
  };

  const handleVerify = async () => {
    if (!selectedFile) {
      setResult('Please select an image first.');
      return;
    }

    setLoading(true);
    setResult(null);

    try {
      const dataUrl = await readFileAsDataURL(selectedFile);
      const base64Image = dataUrl.split(',')[1];

      const response = await fetch('https://2o2i3qgn8j.execute-api.eu-central-1.amazonaws.com/dev/verify-fingerprint', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          fingerprint_image: base64Image,
          user_id: 'user_001',
        }),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! Status: ${response.status}`);
      }

      const data: VerifyResponse = await response.json();
      setResult(`✅ Match: ${data.match}\n📊 Score: ${data.score}\n👤 User ID: ${data.user_id}`);
    } catch (error: Error) { // Changed from 'any' to 'Error'
      setResult(`❌ Error: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-md mx-auto p-6 bg-white rounded-lg shadow-lg">
      <h1 className="text-2xl font-bold text-gray-800 mb-4">🔍 Fingerprint Verification</h1>

      <input
        type="file"
        accept=".tif,.tiff,image/tiff"
        onChange={handleFileChange}
        className="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-indigo-50 file:text-indigo-700 hover:file:bg-indigo-100"
      />

      {selectedFile && (
        <div className="mt-4">
          <canvas
            ref={previewCanvasRef}
            className="w-full max-w-xs rounded-md border border-gray-300 shadow-sm"
          />
        </div>
      )}

      <button
        onClick={handleVerify}
        disabled={loading}
        className={`mt-4 w-full py-2 px-4 rounded-md text-white font-semibold transition-colors ${
          loading
            ? 'bg-gray-400 cursor-not-allowed'
            : 'bg-indigo-600 hover:bg-indigo-700'
        }`}
      >
        {loading ? 'Verifying...' : 'Verify Fingerprint'}
      </button>

      {result && (
        <div className="mt-4 p-4 bg-gray-50 rounded-md text-sm text-gray-800 whitespace-pre-wrap">
          {result}
        </div>
      )}
    </div>
  );
};

export default FingerprintVerifier;