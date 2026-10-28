package de.julianh.sheetopia;

import android.content.Intent;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.provider.DocumentsContract;

import androidx.annotation.NonNull;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String FILE_EXPORT_CHANNEL = "sheetopia/file_export";
    private static final int EXPORT_FILE_REQUEST_CODE = 7301;

    private final ExecutorService ioExecutor = Executors.newSingleThreadExecutor();
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    private MethodChannel.Result pendingExportResult;
    private String pendingExportSourcePath;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), FILE_EXPORT_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (!call.method.equals("exportFile")) {
                        result.notImplemented();
                        return;
                    }
                    if (pendingExportResult != null) {
                        result.error("already_active", "another export is already in progress", null);
                        return;
                    }
                    String sourcePath = call.argument("path");
                    if (sourcePath == null || !new File(sourcePath).canRead()) {
                        result.error("export_failed", "cannot read " + sourcePath, null);
                        return;
                    }
                    Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
                    intent.addCategory(Intent.CATEGORY_OPENABLE);
                    intent.setType(call.argument("mimeType"));
                    intent.putExtra(Intent.EXTRA_TITLE, (String) call.argument("fileName"));
                    try {
                        startActivityForResult(intent, EXPORT_FILE_REQUEST_CODE);
                    } catch (Exception e) {
                        result.error("export_failed", e.getMessage(), null);
                        return;
                    }
                    pendingExportResult = result;
                    pendingExportSourcePath = sourcePath;
                });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode != EXPORT_FILE_REQUEST_CODE) {
            super.onActivityResult(requestCode, resultCode, data);
            return;
        }
        MethodChannel.Result result = pendingExportResult;
        String sourcePath = pendingExportSourcePath;
        pendingExportResult = null;
        pendingExportSourcePath = null;
        if (result == null) return;

        Uri uri = data != null ? data.getData() : null;
        if (resultCode != RESULT_OK || uri == null) {
            result.success(null);
            return;
        }

        ioExecutor.execute(() -> {
            boolean written = false;
            try (InputStream in = new FileInputStream(sourcePath);
                 OutputStream out = getContentResolver().openOutputStream(uri, "wt")) {
                if (out == null) throw new IllegalStateException("cannot open " + uri);
                written = true;
                byte[] buffer = new byte[64 * 1024];
                int read;
                while ((read = in.read(buffer)) != -1) {
                    out.write(buffer, 0, read);
                }
            } catch (Exception e) {
                // the picker may return an existing document the user chose to overwrite, keep it if untouched
                if (written) {
                    try {
                        DocumentsContract.deleteDocument(getContentResolver(), uri);
                    } catch (Exception ignored) {
                    }
                }
                mainHandler.post(() -> result.error("export_failed", e.getMessage(), null));
                return;
            }
            mainHandler.post(() -> result.success(uri.toString()));
        });
    }
}
