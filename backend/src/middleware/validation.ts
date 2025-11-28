import { Request, Response, NextFunction } from 'express';

/**
 * Validation utilities for common input patterns
 */

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const PASSWORD_MIN_LENGTH = 8;
const NAME_MAX_LENGTH = 100;
const PHONE_REGEX = /^[\d\s\-\+\(\)]+$/;

export interface ValidationError {
  field: string;
  message: string;
}

export interface ValidatedRequest extends Request {
  validationErrors?: ValidationError[];
}

/**
 * Validate email format
 */
export const validateEmail = (email: string): boolean => {
  if (!email || typeof email !== 'string') return false;
  return EMAIL_REGEX.test(email) && email.length <= 255;
};

/**
 * Validate password strength
 */
export const validatePassword = (password: string): { valid: boolean; errors: string[] } => {
  const errors: string[] = [];

  if (!password || typeof password !== 'string') {
    return { valid: false, errors: ['Password is required'] };
  }

  if (password.length < PASSWORD_MIN_LENGTH) {
    errors.push(`Password must be at least ${PASSWORD_MIN_LENGTH} characters`);
  }

  if (!/[A-Z]/.test(password)) {
    errors.push('Password must contain at least one uppercase letter');
  }

  if (!/[a-z]/.test(password)) {
    errors.push('Password must contain at least one lowercase letter');
  }

  if (!/[0-9]/.test(password)) {
    errors.push('Password must contain at least one number');
  }

  if (!/[!@#$%^&*]/.test(password)) {
    errors.push('Password must contain at least one special character (!@#$%^&*)');
  }

  return { valid: errors.length === 0, errors };
};

/**
 * Validate name format
 */
export const validateName = (name: string | null | undefined): boolean => {
  if (!name) return true; // Optional field
  if (typeof name !== 'string') return false;
  return name.length > 0 && name.length <= NAME_MAX_LENGTH && !/[<>]/.test(name);
};

/**
 * Validate phone format
 */
export const validatePhone = (phone: string | null | undefined): boolean => {
  if (!phone) return true; // Optional field
  if (typeof phone !== 'string') return false;
  return PHONE_REGEX.test(phone) && phone.length >= 10 && phone.length <= 20;
};

/**
 * Middleware to validate login/register request body
 */
export const validateAuthRequest = (req: ValidatedRequest, res: Response, next: NextFunction) => {
  const { email, password, name, phone } = req.body;
  const errors: ValidationError[] = [];

  // Email validation
  if (!validateEmail(email)) {
    errors.push({ field: 'email', message: 'Invalid email format' });
  }

  // Password validation
  const passwordValidation = validatePassword(password);
  if (!passwordValidation.valid) {
    errors.push({
      field: 'password',
      message: passwordValidation.errors.join('; '),
    });
  }

  // Name validation (optional for login, required for register)
  if (req.path.includes('/register')) {
    if (!name) {
      errors.push({ field: 'name', message: 'Name is required for registration' });
    } else if (!validateName(name)) {
      errors.push({ field: 'name', message: 'Invalid name format' });
    }
  } else if (name && !validateName(name)) {
    errors.push({ field: 'name', message: 'Invalid name format' });
  }

  // Phone validation (optional)
  if (phone && !validatePhone(phone)) {
    errors.push({ field: 'phone', message: 'Invalid phone format' });
  }

  if (errors.length > 0) {
    return res.status(400).json({ error: 'Validation failed', details: errors });
  }

  next();
};

/**
 * Middleware to sanitize input (remove HTML tags and trim whitespace)
 */
export const sanitizeInput = (req: Request, res: Response, next: NextFunction) => {
  const sanitize = (obj: any): any => {
    if (typeof obj === 'string') {
      return obj.trim().replace(/<[^>]*>/g, ''); // Remove HTML tags
    }
    if (obj !== null && typeof obj === 'object') {
      if (Array.isArray(obj)) {
        return obj.map(sanitize);
      }
      const sanitized: any = {};
      for (const key in obj) {
        sanitized[key] = sanitize(obj[key]);
      }
      return sanitized;
    }
    return obj;
  };

  req.body = sanitize(req.body);
  next();
};
