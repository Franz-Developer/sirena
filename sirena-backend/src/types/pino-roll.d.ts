// C:\sirena\sirena-backend\src\types\pino-roll.d.ts
declare module 'pino-roll' {
    import { DestinationStream } from 'pino';

    interface PinoRollOptions {
        file: string;
        frequency?: 'daily' | 'weekly' | 'monthly' | 'custom';
        size?: string;
        compress?: boolean;
        limit?: {
            count?: number;
            days?: number;
        };
        custom?: (date: Date) => string;
    }

    function pinoRoll(options: PinoRollOptions): DestinationStream;

    export = pinoRoll;
}
