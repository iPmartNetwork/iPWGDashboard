<template>
  <div class="table-responsive">
    <table class="table table-hover table-sm align-middle">
      <thead class="table-light">
        <tr>
          <th scope="col" style="width: 2%;"><LocaleText t="Status"></LocaleText></th>
          <th scope="col"><LocaleText t="Name"></LocaleText></th>
          <th scope="col"><LocaleText t="Public Key"></LocaleText></th>
          <th scope="col"><LocaleText t="Allowed IPs"></LocaleText></th>
          <th scope="col" class="text-center"><LocaleText t="Data Usage (R/S/T)"></LocaleText></th>
          <th scope="col"><LocaleText t="Last Handshake"></LocaleText></th>
          <th scope="col" class="text-center"><LocaleText t="Actions"></LocaleText></th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="peer in peers" :key="peer.id">
          <td class="text-center">
            <span v-if="!isRestrictedList">
              <i class="bi bi-circle-fill text-success" v-if="peer.status === 'running'" :title="GetLocale('Running')"></i>
              <i class="bi bi-circle-fill text-warning" v-else-if="peer.status === 'stopped' && peer.latest_handshake !== 'N/A' && peer.latest_handshake !== 'No Handshake'" :title="GetLocale('Idle/Stopped')"></i>
              <i class="bi bi-circle-fill text-danger" v-else :title="GetLocale('Never Connected / No Handshake')"></i>
            </span>
            <span v-else>
              <i class="bi bi-slash-circle-fill text-muted" :title="GetLocale('Access Restricted')"></i>
            </span>
          </td>
          <td>
            <div class="fw-bold">{{ peer.name || GetLocale('Unnamed Peer') }}</div>
            <small class="text-muted" v-if="peer.name">{{ peer.id.substring(0, 12) }}...</small>
          </td>
          <td>
            <span class="font-monospace small" :title="peer.id">{{ peer.id.substring(0, 20) }}...</span>
            <button class="btn btn-sm btn-link p-0 ms-1" @click="copyToClipboard(peer.id)" :title="GetLocale('Copy Public Key')">
              <i class="bi bi-clipboard"></i>
            </button>
          </td>
          <td><span class="font-monospace small">{{ peer.allowed_ip }}</span></td>
          <td class="text-center font-monospace small">
            <span :title="GetLocale('Received')">{{ formatBytes(peer.total_receive + peer.cumu_receive) }}</span> /
            <span :title="GetLocale('Sent')">{{ formatBytes(peer.total_sent + peer.cumu_sent) }}</span> /
            <span :title="GetLocale('Total')">{{ formatBytes(peer.total_data + peer.cumu_data) }}</span>
          </td>
          <td>
            <span v-if="peer.latest_handshake === 'N/A' || peer.latest_handshake === 'No Handshake'">
              <LocaleText t="No Handshake"></LocaleText>
            </span>
            <span v-else :title="formatTimestamp(peer.latest_handshake_raw_timestamp)"> <!-- Assuming raw timestamp is available -->
              {{ formatTimeAgo(peer.latest_handshake_raw_timestamp) || peer.latest_handshake }}
            </span>
          </td>
          <td class="text-center">
            <div class="btn-group btn-group-sm" role="group">
              <button class="btn btn-outline-primary" @click="$emit('editPeer', peer)" :title="GetLocale('Edit Peer')">
                <i class="bi bi-pencil-square"></i>
              </button>
              <button class="btn btn-outline-info" @click="$emit('showQrCode', peer.id)" :title="GetLocale('Show QR Code')">
                <i class="bi bi-qr-code"></i>
              </button>
              <button class="btn btn-outline-secondary" @click="$emit('downloadPeerConfig', peer.id)" :title="GetLocale('Download Config')">
                <i class="bi bi-download"></i>
              </button>
              <button 
                class="btn" 
                :class="isRestrictedList ? 'btn-outline-success' : 'btn-outline-warning'" 
                @click="$emit('togglePeerStatus', peer, isRestrictedList)" 
                :title="isRestrictedList ? GetLocale('Allow Access') : GetLocale('Restrict Peer')">
                <i class="bi" :class="isRestrictedList ? 'bi-check-circle' : 'bi-slash-circle'"></i>
              </button>
              <button class="btn btn-outline-danger" @click="$emit('deletePeer', peer)" :title="GetLocale('Delete Peer')">
                <i class="bi bi-trash"></i>
              </button>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup>
import { defineProps, defineEmits } from 'vue';
import { GetLocale } from "@/utilities/locale.js";
import LocaleText from "@/components/text/localeText.vue";
// import { useToast } from 'vue-toastification';

// const toast = useToast();

const props = defineProps({
  peers: {
    type: Array,
    required: true
  },
  configName: {
    type: String,
    required: true
  },
  protocol: {
    type: String,
    default: 'wg'
  },
  isRestrictedList: {
    type: Boolean,
    default: false
  }
});

defineEmits(['editPeer', 'deletePeer', 'togglePeerStatus', 'downloadPeerConfig', 'showQrCode', 'refreshPeers']);

const formatBytes = (bytes, decimals = 2) => {
  if (!+bytes) return '0 Bytes';
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(dm))} ${sizes[i]}`;
};

const formatTimeAgo = (timestamp) => {
    if (!timestamp || timestamp <= 0) return GetLocale('N/A');
    const now = new Date();
    const secondsPast = (now.getTime() - new Date(timestamp * 1000).getTime()) / 1000;

    if (secondsPast < 60) return GetLocale('Just now');
    if (secondsPast < 3600) return `${Math.round(secondsPast / 60)} ${GetLocale('min ago')}`;
    if (secondsPast <= 86400) return `${Math.round(secondsPast / 3600)} ${GetLocale('hr ago')}`;
    
    const days = Math.round(secondsPast / 86400);
    if (days < 7) return `${days} ${GetLocale('day(s) ago')}`;
    
    // For older dates, show the actual date
    const date = new Date(timestamp * 1000);
    return date.toLocaleDateString(GetLocale('date_locale_code', 'en-US'), { // 'en-US' as fallback
        year: 'numeric', month: 'short', day: 'numeric' 
    });
};

const formatTimestamp = (timestamp) => {
    if (!timestamp || timestamp <= 0) return GetLocale('N/A');
    const date = new Date(timestamp * 1000);
    return date.toLocaleString(GetLocale('datetime_locale_code', 'en-US')); // 'en-US' as fallback
};


const copyToClipboard = async (text) => {
  try {
    await navigator.clipboard.writeText(text);
    // toast.success(GetLocale("Copied to clipboard!"));
    alert(GetLocale("Copied to clipboard!"));
  } catch (err) {
    console.error('Failed to copy: ', err);
    // toast.error(GetLocale("Failed to copy to clipboard."));
    alert(GetLocale("Failed to copy to clipboard."));
  }
};

// Note: The peer object from backend might need a 'latest_handshake_raw_timestamp' field (unix timestamp number)
// for formatTimeAgo and formatTimestamp to work correctly.
// The existing 'latest_handshake' seems to be a pre-formatted string like "0:00:05 ago".
</script>

<style scoped>
.table th, .table td {
  white-space: nowrap;
}
.font-monospace {
  font-family: var(--bs-font-monospace);
}
</style>
