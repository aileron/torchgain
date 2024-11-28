import React from 'react'
import { Button } from "@/components/ui/button";

interface HomeProps {
  message?: string
}

export default function Home({ message = "Welcome" }: HomeProps) {
  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold text-blue-600">
        {message}!
      </h1>
      <p className="mt-4">
        Built with Rails + Inertia + React + Tailwind CSS + shadcn/ui
      </p>

      <Button
        onClick={() => alert('TEST')}
        variant="outline"
        className="w-full"
      >
        TEST
      </Button>
    </div>
  )
}
