import '../models/manager_definition.dart';

const List<ManagerDefinition> sampleManagers = [
  ManagerDefinition(
    id: 'storage_manager',
    title: 'Storage Manager',
    description: 'Key-value storage wrapper with a simple singleton API.',
    className: 'StorageManager',
    exportCode: "export { StorageManager } from './src/main/ets/managers/StorageManager';",
    permissions: ['ohos.permission.INTERNET'],
    code: r'''
import preferences from '@ohos.data.preferences';

export class StorageManager {
  private static _instance: StorageManager | null = null;
  private _prefs: preferences.Preferences | null = null;

  static get instance(): StorageManager {
    if (StorageManager._instance == null) {
      StorageManager._instance = new StorageManager();
    }
    return StorageManager._instance;
  }

  async init(context: Context): Promise<void> {
    if (this._prefs != null) return;
    const pref = await preferences.getPreferences(context, 'app_prefs');
    this._prefs = pref;
  }

  async setString(key: string, value: string): Promise<void> {
    if (this._prefs == null) throw new Error('StorageManager not initialized');
    await this._prefs.put(key, value);
    await this._prefs.flush();
  }

  async getString(key: string, defaultValue: string = ''): Promise<string> {
    if (this._prefs == null) throw new Error('StorageManager not initialized');
    const v = await this._prefs.get(key, defaultValue);
    return String(v);
  }
}
''',
  ),
  ManagerDefinition(
    id: 'location_manager',
    title: 'Location Manager',
    description: 'A minimal location permission + last-known location helper.',
    className: 'LocationManager',
    exportCode: "export { LocationManager } from './src/main/ets/managers/LocationManager';",
    permissions: ['ohos.permission.LOCATION'],
    code: r'''
import geoLocationManager from '@ohos.geoLocationManager';

export class LocationManager {
  private static _instance: LocationManager | null = null;

  static get instance(): LocationManager {
    if (LocationManager._instance == null) {
      LocationManager._instance = new LocationManager();
    }
    return LocationManager._instance;
  }

  async isLocationEnabled(): Promise<boolean> {
    return geoLocationManager.isLocationEnabled();
  }

  async getLastLocation(): Promise<geoLocationManager.Location | null> {
    try {
      const loc = await geoLocationManager.getLastLocation();
      return loc ?? null;
    } catch (e) {
      return null;
    }
  }
}
''',
  ),
];

