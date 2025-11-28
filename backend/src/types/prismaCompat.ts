// Compatibility types for environments where Prisma enums may not be generated
export type VibeType = 'CHILL' | 'UPBEAT' | 'FOCUSED' | 'CUSTOM';
export type RideStatus = 'PENDING' | 'ACCEPTED' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED';

export const VibeTypeValues: VibeType[] = ['CHILL', 'UPBEAT', 'FOCUSED', 'CUSTOM'];
export const RideStatusValues: RideStatus[] = ['PENDING', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'];
