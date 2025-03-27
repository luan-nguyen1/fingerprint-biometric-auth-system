'use client';

import React from 'react';
import { useBorderControl } from '@/hooks/useBorderControl';

import RegisterPanel from '@/components/panels/RegisterPanel';
import FacePanel from '@/components/panels/FacePanel';
import UploadHistoryPanel from '@/components/panels/UploadHistoryPanel';
import BoardingPassPanel from '@/components/panels/BoardingPassPanel';
import IdentityMatchPanel from '@/components/panels/IdentityMatchPanel';
import TerminalActivityPanel from '@/components/panels/TerminalActivityPanel';
import GlobalEntryPanel from '@/components/panels/GlobalEntryPanel';
import AnomalyPanel from '@/components/panels/AnomalyPanel';
import ConfigPanel from '@/components/panels/ConfigPanel';
import AccessLogPanel from '@/components/panels/AccessLogPanel';

export default function BorderControlDashboard() {
  const {
    error,
    setError,
    extractedName,
    extractedPassportNo,
    passportFile,
    fingerprintFile,
    setPassportFile,
    setFingerprintFile,
    setPassportInfo,
    handlePassportUpload,
    handleRegister,
    handleVerify,
  } = useBorderControl();

  return (
    <div className="min-h-screen bg-sky-950 text-white p-6 space-y-10">
      <h1 className="text-4xl font-extrabold text-center mb-6">🛂 Border Control System</h1>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-8">
        <RegisterPanel
          onRegister={handleRegister}
          setPassportInfo={setPassportInfo}
          setError={setError}
          passportFile={passportFile}
          fingerprintFile={fingerprintFile}
          setPassportFile={setPassportFile}
          setFingerprintFile={setFingerprintFile}
          extractedName={extractedName}
          extractedPassportNo={extractedPassportNo}
        />
        <FacePanel />
        <IdentityMatchPanel onVerify={handleVerify} setError={setError} />
        <BoardingPassPanel />
        <UploadHistoryPanel />
        <TerminalActivityPanel />
        <GlobalEntryPanel />
        <AnomalyPanel />
      </div>

      <div className="mt-12">
        <h2 className="text-2xl font-bold mb-4">🛡️ Admin Control</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <ConfigPanel />
          <AccessLogPanel />
        </div>
      </div>

      {error && (
        <div className="mt-6 max-w-3xl mx-auto text-red-300 bg-red-900 p-4 rounded border border-red-700">
          ❌ {error}
        </div>
      )}
    </div>
  );
}
