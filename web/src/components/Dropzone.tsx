// components/Dropzone.tsx
'use client';

import React from 'react';

interface DropzoneProps {
  label: string;
  accept: string;
  onDrop: (file: File | null) => void;
}

export default function Dropzone({ label, accept, onDrop }: DropzoneProps) {
  return (
    <div className="border-2 border-dashed border-sky-500 rounded p-4 text-center hover:bg-sky-800/30 transition">
      <p className="text-sm">{label}</p>
      <input
        type="file"
        accept={accept}
        onChange={(e) => onDrop(e.target.files?.[0] || null)}
        className="mt-2 file:bg-sky-600 file:text-white file:px-4 file:py-2 file:rounded file:border-0 file:cursor-pointer hover:file:bg-sky-500"
      />
    </div>
  );
}
