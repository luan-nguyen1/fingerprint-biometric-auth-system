'use client';

import { useState } from 'react';

const API_BASE = 'https://a47hcdsuul.execute-api.eu-central-1.amazonaws.com/dev';

export function useBorderControl() {
  const [error, setError] = useState<string | null>(null);
  const [extractedName, setExtractedName] = useState('');
  const [extractedPassportNo, setExtractedPassportNo] = useState('');
  const [passportFile, setPassportFile] = useState<File | null>(null);
  const [fingerprintFile, setFingerprintFile] = useState<File | null>(null);

  const setPassportInfo = (data: { name: string; passport_no: string }) => {
    setExtractedName(data.name);
    setExtractedPassportNo(data.passport_no);
  };

  const handleRegister = async () => {
    if (!passportFile || !fingerprintFile || !extractedName || !extractedPassportNo) {
      setError('Please upload all required files and extract passport info.');
      return;
    }

    try {
      const formData = new FormData();
      formData.append('name', extractedName);
      formData.append('passport_no', extractedPassportNo);
      formData.append('passport_image', passportFile);
      formData.append('fingerprint_image', fingerprintFile);

      const res = await fetch(`${API_BASE}/register-traveler`, {
        method: 'POST',
        body: formData,
      });

      const result = await res.json();

      if (!res.ok) throw new Error(result.error || 'Registration failed');

      alert('✅ Traveler registered successfully!');
    } catch (err: any) {
      setError(err.message || 'Failed to register traveler');
    }
  };

  const handleVerify = async (file: File) => {
    const reader = new FileReader();
    return new Promise<any>((resolve, reject) => {
      reader.onload = async () => {
        try {
          const base64 = (reader.result as string).split(',')[1];
          const res = await fetch(`${API_BASE}/verify-fingerprint`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ fingerprint_image: base64 }),
          });
          const data = await res.json();
          resolve(data);
        } catch (err) {
          reject(err);
        }
      };
      reader.readAsDataURL(file);
    });
  };

  return {
    error,
    setError,
    extractedName,
    extractedPassportNo,
    passportFile,
    fingerprintFile,
    setPassportFile,
    setFingerprintFile,
    setPassportInfo,
    handleRegister,
    handleVerify,
  };
}
