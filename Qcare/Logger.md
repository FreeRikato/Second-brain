```ts
import path from "node:path";

import { createLogger, format, transports } from "winston";
import DailyRotateFile from "winston-daily-rotate-file";

import { ApplicationInsightsTransport } from "@/configs/appInsightsTransport";
import { NodeEnv } from "@/shared/enums/nodeEnv.enum";

const { timestamp, combine, errors } = format;

const consoleTransport = new transports.Console();

const fileTransport = new DailyRotateFile({
  frequency: "1h",
  zippedArchive: true,
  filename: "%DATE%.log",
  dirname: path.join(process.cwd(), "logs/"),
  maxSize: "10m",
  maxFiles: "14d",
  datePattern: "YYYY-MM-DDTHH",
  utc: true,
  createSymlink: true,
  symlinkName: path.join(process.cwd(), "logs/winston.log"), // The 'current' log file
});

const logger = createLogger({
  level: "info",
  format: combine(
    timestamp(),
    errors({ stack: true }),
    format.printf(({ timestamp, level, message, ...meta }) => {
      return JSON.stringify(
        {
          timestamp,
          level,
          message,
          ...meta,
        },
        null,
        2,
      ).replace(/\\/g, "");
    }),
  ),
  transports: [fileTransport],
  handleExceptions: true,
  handleRejections: true,
});

if (process.env.NODE_ENV !== NodeEnv.TEST) {
  logger.add(consoleTransport);
}

if (
  process.env.NODE_ENV !== NodeEnv.TEST &&
  process.env.NODE_ENV !== NodeEnv.LOCAL
) {
  logger.add(new ApplicationInsightsTransport());
}

export default logger;
```