<script setup>
import { ref, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import UazapiAPI from 'dashboard/api/uazapi';
import PageHeader from '../../SettingsSubPageHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Spinner from 'shared/components/Spinner.vue';

const { t } = useI18n();
const router = useRouter();

const STEP_FORM = 'form';
const STEP_QR = 'qr';
const STEP_DONE = 'done';

const step = ref(STEP_FORM);
const serverUrl = ref('');
const adminToken = ref('');
const instanceName = ref('');
const inboxName = ref('');
const qrcode = ref('');
const paircode = ref('');
const profileName = ref('');
const inboxId = ref(null);
const isCreating = ref(false);
let pollTimer = null;

const mustBeServerUrl = (value = '') => (value ? value.startsWith('http') : true);

const v$ = useVuelidate(
  {
    serverUrl: { required, mustBeServerUrl },
    adminToken: { required },
    instanceName: { required },
  },
  { serverUrl, adminToken, instanceName }
);

const stopPolling = () => {
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
};

const goToAddAgents = () => {
  router.replace({
    name: 'settings_inboxes_add_agents',
    params: { page: 'new', inbox_id: inboxId.value },
  });
};

const pollStatus = async () => {
  try {
    const { data } = await UazapiAPI.status(inboxId.value);
    if (data.qrcode) qrcode.value = data.qrcode;
    if (data.paircode) paircode.value = data.paircode;
    if (data.logged_in && data.configured) {
      stopPolling();
      profileName.value = data.profile_name || data.owner || '';
      step.value = STEP_DONE;
      setTimeout(goToAddAgents, 1500);
    }
  } catch (error) {
    // mantém o polling; erros intermitentes de rede não devem encerrar o fluxo
  }
};

const createInstance = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  isCreating.value = true;
  try {
    const { data } = await UazapiAPI.setup({
      server_url: serverUrl.value.trim(),
      admin_token: adminToken.value.trim(),
      instance_name: instanceName.value.trim(),
      inbox_name: inboxName.value.trim(),
    });
    inboxId.value = data.inbox_id;
    qrcode.value = data.qrcode || '';
    paircode.value = data.paircode || '';
    step.value = STEP_QR;
    pollTimer = setInterval(pollStatus, 3000);
  } catch (error) {
    useAlert(
      error?.response?.data?.error || t('INBOX_MGMT.ADD.UAZAPI.ERROR_MESSAGE')
    );
  } finally {
    isCreating.value = false;
  }
};

onBeforeUnmount(stopPolling);
</script>

<template>
  <div class="h-full w-full p-6 col-span-6">
    <PageHeader
      :header-title="t('INBOX_MGMT.ADD.UAZAPI.TITLE')"
      :header-content="t('INBOX_MGMT.ADD.UAZAPI.DESC')"
    />

    <form
      v-if="step === 'form'"
      class="flex flex-wrap flex-col mx-0"
      @submit.prevent="createInstance()"
    >
      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.serverUrl.$error }">
          {{ t('INBOX_MGMT.ADD.UAZAPI.SERVER_URL.LABEL') }}
          <input
            v-model="serverUrl"
            type="text"
            :placeholder="t('INBOX_MGMT.ADD.UAZAPI.SERVER_URL.PLACEHOLDER')"
            @blur="v$.serverUrl.$touch"
          />
          <span v-if="v$.serverUrl.$error" class="message">
            {{ t('INBOX_MGMT.ADD.UAZAPI.SERVER_URL.ERROR') }}
          </span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.adminToken.$error }">
          {{ t('INBOX_MGMT.ADD.UAZAPI.ADMIN_TOKEN.LABEL') }}
          <input
            v-model="adminToken"
            type="password"
            :placeholder="t('INBOX_MGMT.ADD.UAZAPI.ADMIN_TOKEN.PLACEHOLDER')"
            @blur="v$.adminToken.$touch"
          />
          <span v-if="v$.adminToken.$error" class="message">
            {{ t('INBOX_MGMT.ADD.UAZAPI.ADMIN_TOKEN.ERROR') }}
          </span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.instanceName.$error }">
          {{ t('INBOX_MGMT.ADD.UAZAPI.INSTANCE_NAME.LABEL') }}
          <input
            v-model="instanceName"
            type="text"
            :placeholder="t('INBOX_MGMT.ADD.UAZAPI.INSTANCE_NAME.PLACEHOLDER')"
            @blur="v$.instanceName.$touch"
          />
          <span v-if="v$.instanceName.$error" class="message">
            {{ t('INBOX_MGMT.ADD.UAZAPI.INSTANCE_NAME.ERROR') }}
          </span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label>
          {{ t('INBOX_MGMT.ADD.UAZAPI.INBOX_NAME.LABEL') }}
          <input
            v-model="inboxName"
            type="text"
            :placeholder="t('INBOX_MGMT.ADD.UAZAPI.INBOX_NAME.PLACEHOLDER')"
          />
        </label>
      </div>

      <div class="w-full mt-4">
        <NextButton
          :is-loading="isCreating"
          type="submit"
          solid
          blue
          :label="t('INBOX_MGMT.ADD.UAZAPI.SUBMIT_BUTTON')"
        />
      </div>
    </form>

    <div
      v-else-if="step === 'qr'"
      class="flex flex-col items-center gap-4 py-8"
    >
      <h3 class="text-lg font-medium text-n-slate-12">
        {{ t('INBOX_MGMT.ADD.UAZAPI.QR.TITLE') }}
      </h3>
      <p class="max-w-md text-center text-n-slate-11">
        {{ t('INBOX_MGMT.ADD.UAZAPI.QR.HELP') }}
      </p>
      <img
        v-if="qrcode"
        :src="qrcode"
        :alt="t('INBOX_MGMT.ADD.UAZAPI.QR.TITLE')"
        class="w-64 h-64 rounded-xl bg-white p-3"
      />
      <div v-else class="flex items-center gap-2 text-n-slate-11">
        <Spinner size="small" />
        {{ t('INBOX_MGMT.ADD.UAZAPI.QR.WAITING') }}
      </div>
      <p v-if="paircode" class="text-n-slate-11">
        {{ t('INBOX_MGMT.ADD.UAZAPI.QR.PAIRCODE') }}
        <span class="font-mono font-semibold text-n-slate-12">{{
          paircode
        }}</span>
      </p>
      <div class="flex items-center gap-2 text-n-blue-11">
        <Spinner size="small" />
        {{ t('INBOX_MGMT.ADD.UAZAPI.QR.POLLING') }}
      </div>
    </div>

    <div v-else class="flex flex-col items-center gap-4 py-8">
      <span class="i-lucide-circle-check-big size-12 text-n-teal-9" />
      <h3 class="text-lg font-medium text-n-slate-12">
        {{ t('INBOX_MGMT.ADD.UAZAPI.QR.CONNECTED') }}
      </h3>
      <p v-if="profileName" class="text-n-slate-11">{{ profileName }}</p>
    </div>
  </div>
</template>
