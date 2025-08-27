const ExportType = {
    LINK: 'LINK',
    FILE: 'FILE',
    APP: 'APP'
}

class ConfigExportFile {
    async export(data) {
        const blob = new Blob([data], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.download = 'config.json';
        a.href = url;
        a.click();
        URL.revokeObjectURL(url);
        showToastSuccess('Opa! configuración exportada con exito!');;
    }
}

class ConfigExportUrl {
    async export(data) {
        showToastInfo('Aguarde mientras la configuración se exportada...');
        const form = new FormData();
        const file = new File([data], 'config.json', { type: 'application/json' });
        form.append('file', file);

        try {
            const response = await fetch('/config/upload/file', {
                method: 'POST',
                body: form
            });
            const result = await response.json();
            if (result.status != 200)
                throw new Error();

            showToastSuccess('Opa! configuración exportada con exito!');
            return result.data;
        } catch (e) {
            showToastError('ay! No fue posible exportar la configuración!');
        }
    }
}

class ConfigExportApp {
    async export(data) {
        if (!this.validate(data)) return;

        const options = {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ config: data })
        };

        try {
            const response = await fetch('/config/copy', options);
            const result = await response.json();
            if (result.config) {
                showToastSuccess('Opa! configuración exportada con exito!');
                return `vpn://${result.config}`
            }
        } catch (e) {
            showToastError('ay! No fue posible importar la configuración!');
        }
    }

    validate(data) {
        const config = JSON.parse(data);
        if (Array.isArray(config)) {
            showToastError('Infelizmente no es posibel exportar múltiples Configuraciones para la app!');
            return false;
        }
        return true;
    }
}

class ConfigExportFactory {
    static create(type) {
        switch (type) {
            case ExportType.FILE:
                return new ConfigExportFile();
            case ExportType.LINK:
                return new ConfigExportUrl();
            case ExportType.APP:
                return new ConfigExportApp();
            default:
                throw new Error('Invalid export type!');
        }
    }
}

export default ConfigExportFactory;