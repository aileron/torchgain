import React, { useState, useCallback } from "react";
import { MapContainer, TileLayer, Marker, useMapEvents } from "react-leaflet";
import { LatLngExpression, Icon, DivIcon } from 'leaflet';
import { GeoHex } from "@uupaa/geohex";
import { router } from "@inertiajs/react";
import "leaflet/dist/leaflet.css";

interface Location {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
}

interface Props {
  initialZoom: number;
  initialCode: string;
  locations: Location[];
}

export interface LatLng {
  lat: number;
  lng: number;
  lon: number;
}

interface GeoHexZone {
  lat: number;
  lng: number;
  lon: number;
  x: number;
  y: number;
  code: string;
  level: number;
  equals(zone: GeoHexZone): boolean;
  getHexSize(): number;
  getHexCoords(): LatLng[];
}

// マップイベントを監視するコンポーネント
const MapEventHandler: React.FC<{
  onCenterChange: (zoom: number, newCenter: GeoHexZone) => void;
}> = ({ onCenterChange }) => {
  const map = useMapEvents({
    moveend: () => {
      const zoom = map.getZoom();
      const mapCenter = map.getCenter();
      const hex = GeoHex.getZoneByLocation(mapCenter.lat, mapCenter.lng, 10);
      onCenterChange(zoom, hex);
    },
  });

  return null;
};

// カスタムアイコンの定義
const customIcon = new DivIcon({
  html: `
    <svg 
      width="24" 
      height="24" 
      viewBox="0 0 24 24" 
      fill="none" 
      xmlns="http://www.w3.org/2000/svg"
    >
      <circle cx="12" cy="12" r="8" fill="#FF4444" stroke="white" stroke-width="2"/>
    </svg>
  `,
  className: '',  // デフォルトのクラスを削除
  iconSize: [24, 24],
  iconAnchor: [12, 12],
});

const MapUi = ({ initialZoom = 16, initialCode, locations }: Props) => {
  const initialHex = GeoHex.getZoneByCode(initialCode);
  const center: LatLngExpression = [initialHex.lat, initialHex.lng];
  const [currentCenter, setCurrentCenter] = useState<GeoHexZone>(initialHex);
  const [selectedlocation, setSelectedlocation] = useState<Location>();
  const handleCenterChange = useCallback(
    (zoom: number, newCenter: GeoHexZone) => {
      router.visit(`/locations/${newCenter.code}/${zoom}/`, {
        preserveScroll: true,
        preserveState: true,
        only: ["locations"],
      });

      // setCurrentCenter(newCenter);
    },
    [],
  );
  const hundleClose = () => {
    setSelectedlocation(undefined);
  };


  return (
    <div className="w-full h-screen relative">
      <MapContainer
        center={center}
        zoom={initialZoom}
        style={{ height: "100%", width: "100%" }}
      >
        <MapEventHandler onCenterChange={handleCenterChange} />

        <TileLayer
          url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png"
        />

        {locations.map((location) => (
          <Marker
            key={location.id}
            position={[location.latitude, location.longitude]}
            icon={customIcon}
            eventHandlers={{
              click: () => setSelectedlocation(location),
            }}
          ></Marker>
        ))}
      </MapContainer>

      <LocationInfo location={selectedlocation} hundleClose={hundleClose} />
    </div>
  );
};

interface locationInfoProps {
  location: Location | undefined;
  hundleClose: () => void;
}

// 情報表示コンポーネント
const LocationInfo = ({ location, hundleClose }: locationInfoProps) => {
  const blank = (
    <div className="p-4 text-center text-gray-500">
      選択すると、ここに詳細が表示されます。
    </div>
  );
  const locationInfo = location ? (
    <div className="p-4">
      <button
        className="absolute top-0 right-0 bg-gray-200 text-gray-700 px-2 py-1 rounded"
        onClick={() => hundleClose()}
      >
        &#x2715;
      </button>
      <h2 className="text-xl font-bold mb-2">{location.name}</h2>

      <button
        className="bg-black text-white px-4 py-2 rounded mt-4 mx-auto block"
        onClick={() => alert(location.name) }
      >
        詳細を見る
      </button>
    </div>
  ) : (
    blank
  );

  return (
    <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 bg-white shadow-lg transition-all duration-300 ease-in-out z-[1000] w-full max-w-3xl">
      {locationInfo}
    </div>
  );
};

const DebugGeoHex = ({ zone }: { zone: GeoHexZone }) => {
  return (
    <div className="absolute top-0 right-0 bg-white p-4 z-[1000] m-2 rounded shadow">
      <h3 className="font-bold">GeoHex Debug Info</h3>
      <div>
        Center: [{zone.lat}, {zone.lng}]
      </div>
      <div>Level: {zone.level}</div>
      <button
        className="bg-blue-500 text-white px-2 py-1 rounded mt-2"
        onClick={() => console.log("Full GeoHex:", zone)}
      >
        Log Full Data
      </button>
    </div>
  );
};

export default MapUi;
