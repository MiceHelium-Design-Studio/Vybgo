import { Request, Response, NextFunction } from 'express';

export interface AppError extends Error {
  status?: number;
}

export const errorHandler = (
  err: AppError,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  // Log the error
  console.error('Error:', err);

  // Determine status code
  const status = err.status || 500;

  // Send error response (maintaining original { error: string } format)
  res.status(status).json({
    error: err.message || 'Internal server error',
  });
};

