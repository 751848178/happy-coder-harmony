# Happy CLI — httpProxy RPC Handler

This document describes the `httpProxy` RPC handler that needs to be added to
the `slopus/happy` repository (specifically `packages/happy-cli`).

## Overview

The mobile app starts a local HTTP server that proxies incoming requests
through the encrypted RPC channel. On the PC side, the Happy CLI daemon
receives these proxied requests, makes the real HTTP call to `localhost`, and
returns the response.

## Files to Create

### `packages/happy-cli/src/modules/proxy/httpProxyHandler.ts`

```typescript
import { logger } from '@/ui/logger';
import axios, { AxiosRequestConfig } from 'axios';

interface HttpProxyRequest {
    method: string;
    path: string;
    targetPort: number;
    headers: Record<string, string>;
    body?: string; // base64-encoded
}

interface HttpProxyResponse {
    success: boolean;
    statusCode?: number;
    headers?: Record<string, string>;
    body?: string; // base64-encoded
    error?: string;
}

const MAX_RESPONSE_SIZE = 10 * 1024 * 1024; // 10 MB
const REQUEST_TIMEOUT = 30_000; // 30 seconds

/**
 * Register the httpProxy RPC handler.
 *
 * SECURITY: This handler ONLY allows requests to 127.0.0.1 on the
 * specified port. All other targets are rejected to prevent SSRF.
 */
export function registerHttpProxyHandler(
    rpcHandlerManager: import('@/api/rpc/RpcHandlerManager').RpcHandlerManager,
): void {
    rpcHandlerManager.registerHandler<HttpProxyRequest, HttpProxyResponse>(
        'httpProxy',
        async (data) => {
            // 1. Validate target port
            if (
                !data.targetPort ||
                data.targetPort < 1024 ||
                data.targetPort > 65535
            ) {
                return {
                    success: false,
                    error: `Invalid target port: ${data.targetPort}. Must be 1024-65535.`,
                };
            }

            // 2. Build the target URL — host is ALWAYS 127.0.0.1
            const targetUrl = `http://127.0.0.1:${data.targetPort}${data.path}`;

            // 3. Decode body if present
            let requestBody: Buffer | undefined;
            if (data.body) {
                try {
                    requestBody = Buffer.from(data.body, 'base64');
                } catch {
                    return { success: false, error: 'Invalid base64 body' };
                }
            }

            // 4. Make the HTTP request
            try {
                const config: AxiosRequestConfig = {
                    method: data.method as any,
                    url: targetUrl,
                    headers: { ...data.headers },
                    data: requestBody,
                    timeout: REQUEST_TIMEOUT,
                    responseType: 'arraybuffer',
                    validateStatus: () => true, // Don't throw on non-2xx
                    maxContentLength: MAX_RESPONSE_SIZE,
                    maxBodyLength: MAX_RESPONSE_SIZE,
                };

                logger.debug(`[httpProxy] ${data.method} ${targetUrl}`);
                const response = await axios.request(config);

                // 5. Collect response headers (skip hop-by-hop)
                const responseHeaders: Record<string, string> = {};
                for (const [key, value] of Object.entries(response.headers)) {
                    if (typeof value !== 'string') continue;
                    const lower = key.toLowerCase();
                    if (
                        lower === 'transfer-encoding' ||
                        lower === 'connection'
                    )
                        continue;
                    responseHeaders[key] = value;
                }

                // 6. Encode body as base64
                const bodyBase64 = response.data
                    ? Buffer.from(response.data as ArrayBuffer).toString('base64')
                    : undefined;

                return {
                    success: true,
                    statusCode: response.status,
                    headers: responseHeaders,
                    body: bodyBase64,
                };
            } catch (error: any) {
                if (error.code === 'ECONNREFUSED') {
                    return {
                        success: false,
                        error: `Connection refused: 127.0.0.1:${data.targetPort}`,
                    };
                }
                if (error.code === 'ETIMEDOUT' || error.code === 'ECONNABORTED') {
                    return {
                        success: false,
                        error: `Request to 127.0.0.1:${data.targetPort} timed out`,
                    };
                }
                return {
                    success: false,
                    error: error.message || 'Unknown proxy error',
                };
            }
        },
    );
}
```

## File to Modify

### `packages/happy-cli/src/modules/common/registerCommonHandlers.ts`

Add at the end of the `registerCommonHandlers` function:

```typescript
import { registerHttpProxyHandler } from '../proxy/httpProxyHandler';

// At the end of registerCommonHandlers():
registerHttpProxyHandler(rpcHandlerManager);
```

Also add the import at the top of the file.

## Testing

1. Start `happy daemon`
2. Start a test HTTP server on the PC: `python3 -m http.server 8080`
3. From the mobile app, start the local proxy:
   ```dart
   await LocalProxyServer.instance.start(sessionId: sid, targetPort: 8080);
   // Access http://127.0.0.1:{localPort}/ from WebView
   ```
4. Verify the directory listing from the Python server appears
