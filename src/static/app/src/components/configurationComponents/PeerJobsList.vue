<template>
  <div class="peer-jobs-list-container mt-4 p-3 border rounded shadow-sm">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h5 class="mb-0">
        <i class="bi bi-list-check me-2"></i>
        <LocaleText t="Scheduled Jobs for Peer:"></LocaleText> <span class="fw-bold">{{ peer.name || peer.id }}</span>
      </h5>
      <button class="btn btn-sm btn-primary" @click="openJobModal()">
        <i class="bi bi-plus-circle me-1"></i>
        <LocaleText t="Add New Job"></LocaleText>
      </button>
    </div>

    <div v-if="isLoading" class="text-center my-3">
      <div class="spinner-border text-primary" role="status">
        <span class="visually-hidden"><LocaleText t="Loading..."></LocaleText></span>
      </div>
    </div>
    <div v-else-if="jobs.length === 0" class="alert alert-secondary text-center">
      <LocaleText t="No scheduled jobs found for this peer."></LocaleText>
    </div>
    <div v-else class="table-responsive">
      <table class="table table-hover table-sm align-middle small">
        <thead class="table-light">
          <tr>
            <th><LocaleText t="Field"></LocaleText></th>
            <th><LocaleText t="Condition"></LocaleText></th>
            <th><LocaleText t="Value"></LocaleText></th>
            <th><LocaleText t="Action"></LocaleText></th>
            <th><LocaleText t="Created"></LocaleText></th>
            <th class="text-end"><LocaleText t="Actions"></LocaleText></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="job in jobs" :key="job.JobID">
            <td><samp>{{ formatField(job.Field) }}</samp></td>
            <td><samp>{{ formatOperator(job.Operator) }}</samp></td>
            <td><samp>{{ job.Value }} {{ job.Field && job.Field.includes('total_') ? 'GB' : '' }}</samp></td>
            <td>
              <span class="badge" :class="getActionBadgeClass(job.Action)">
                {{ formatAction(job.Action) }}
              </span>
            </td>
            <td>{{ formatDate(job.CreationDate) }}</td>
            <td class="text-end">
              <button class="btn btn-sm btn-outline-primary me-1 py-0 px-1" @click="openJobModal(job)" :title="GetLocale('Edit Job')">
                <i class="bi bi-pencil-square"></i>
              </button>
              <button class="btn btn-sm btn-outline-danger py-0 px-1" @click="confirmDeleteJob(job)" :title="GetLocale('Delete Job')">
                <i class="bi bi-trash"></i>
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Peer Job Modal -->
    <PeerJobModal
      :job-to-edit="selectedJobForEdit"
      :configuration-name="configurationName"
      :peer-id="peer.id"
      :peer-name="peer.name"
      @jobSaved="handleJobSaved"
      ref="peerJobModalRef"
    />

    <!-- Confirmation Modal for Deletion (Bootstrap 5) -->
    <div class="modal fade" id="deleteJobConfirmationModal" tabindex="-1" aria-labelledby="deleteJobConfirmationModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="deleteJobConfirmationModalLabel"><LocaleText t="Confirm Deletion"></LocaleText></h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <LocaleText t="Are you sure you want to delete this scheduled job?"></LocaleText>
                    <div v-if="jobToDelete" class="mt-2 small bg-light p-2 rounded">
                        <strong><LocaleText t="Field:"></LocaleText></strong> {{ formatField(jobToDelete.Field) }} <br>
                        <strong><LocaleText t="Condition:"></LocaleText></strong> {{ formatOperator(jobToDelete.Operator) }} {{ jobToDelete.Value }} <br>
                        <strong><LocaleText t="Action:"></LocaleText></strong> {{ formatAction(jobToDelete.Action) }}
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal"><LocaleText t="Cancel"></LocaleText></button>
                    <button type="button" class="btn btn-danger" @click="deleteJob"><LocaleText t="Delete Job"></LocaleText></button>
                </div>
            </div>
        </div>
    </div>

  </div>
</template>

<script setup>
import { ref, onMounted, reactive, watch } from 'vue';
import PeerJobModal from './PeerJobModal.vue'; // مسیر صحیح را بررسی کنید
import { GetLocale } from "@/utilities/locale.js";
import LocaleText from "@/components/text/localeText.vue";
import { Modal as BootstrapModal } from 'bootstrap'; // برای کنترل مدال با جاوااسکریپت

const props = defineProps({
  configurationName: {
    type: String,
    required: true
  },
  peer: { // آبجکت همتا شامل id و name
    type: Object,
    required: true
  }
});

const jobs = ref([]);
const isLoading = ref(false);
const selectedJobForEdit = ref(null);
const jobToDelete = ref(null);
const peerJobModalRef = ref(null); // Reference to the PeerJobModal component instance
let deleteConfirmationModalInstance = null;


const fetchJobs = async () => {
  if (!props.peer || !props.peer.id) return;
  isLoading.value = true;
  try {
    // TODO: فراخوانی API برای گرفتن لیست کارها
    // بر اساس dashboard.py، احتمالاً چیزی شبیه /api/getPeerScheduleJobs?config_name=...&peer_id=...
    // const response = await fetch(`/api/getPeerScheduleJobs?config_name=${props.configurationName}&peer_id=${props.peer.id}`);
    // if (!response.ok) throw new Error('Failed to fetch jobs');
    // const data = await response.json();
    // jobs.value = data.jobs || []; // فرض بر اینکه API یک آبجکت با کلید jobs برمی‌گرداند

    // داده‌های نمونه برای نمایش
    await new Promise(resolve => setTimeout(resolve, 500)); // شبیه‌سازی تاخیر شبکه
    const sampleJobs = [
      { JobID: 'job1', Configuration: props.configurationName, Peer: props.peer.id, Field: 'total_data', Operator: 'lgt', Value: '100', Action: 'restrict', CreationDate: new Date().toISOString() },
      { JobID: 'job2', Configuration: props.configurationName, Peer: props.peer.id, Field: 'latest_handshake', Operator: 'lgt', Value: '7 days', Action: 'delete', CreationDate: new Date(Date.now() - 86400000 * 5).toISOString() },
    ];
    // Filter sample jobs for the current peer if needed, though they are constructed with peer.id
    jobs.value = sampleJobs.filter(j => j.Peer === props.peer.id && j.Configuration === props.configurationName);

  } catch (error) {
    console.error("Error fetching peer jobs:", error);
    jobs.value = [];
    // نمایش خطا به کاربر
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  fetchJobs();
  const modalElement = document.getElementById('deleteJobConfirmationModal');
  if (modalElement) {
    deleteConfirmationModalInstance = new BootstrapModal(modalElement);
  }
});

watch(() => props.peer.id, (newPeerId, oldPeerId) => {
  if (newPeerId !== oldPeerId) {
    fetchJobs();
  }
});

const openJobModal = (job = null) => {
  selectedJobForEdit.value = job ? { ...job } : null; // Pass a copy or null for new job
  // برای باز کردن مدال PeerJobModal، باید از طریق ref به آن دسترسی پیدا کرد
  // و یک متد عمومی در PeerJobModal برای نمایش مدال فراخوانی کرد،
  // یا اینکه خود PeerJobModal با استفاده از Bootstrap data attributes باز شود.
  // در اینجا فرض می‌کنیم PeerJobModal با data-bs-toggle و data-bs-target مدیریت می‌شود.
  // اگر نیاز به کنترل برنامه‌نویسی دارید:
  const modalElement = document.getElementById('peerJobModal'); // ID مدال در PeerJobModal.vue
  if (modalElement) {
    const modal = BootstrapModal.getOrCreateInstance(modalElement);
    modal.show();
  }
};

const handleJobSaved = (savedJob) => {
  // پس از ذخیره یا ویرایش موفقیت‌آمیز یک کار
  fetchJobs(); // بارگذاری مجدد لیست کارها
  const modalElement = document.getElementById('peerJobModal');
  if (modalElement) {
    const modal = BootstrapModal.getInstance(modalElement);
    if (modal) modal.hide();
  }
};

const confirmDeleteJob = (job) => {
  jobToDelete.value = job;
  if (deleteConfirmationModalInstance) {
    deleteConfirmationModalInstance.show();
  }
};

const deleteJob = async () => {
  if (!jobToDelete.value) return;
  try {
    // TODO: فراخوانی API برای حذف کار
    // بر اساس dashboard.py، احتمالاً چیزی شبیه /api/deletePeerScheduleJob
    // const response = await fetch('/api/deletePeerScheduleJob', {
    //   method: 'POST', // یا DELETE
    //   headers: { 'Content-Type': 'application/json' },
    //   body: JSON.stringify({ JobID: jobToDelete.value.JobID, Configuration: props.configurationName, Peer: props.peer.id })
    // });
    // if (!response.ok) throw new Error('Failed to delete job');
    
    await new Promise(resolve => setTimeout(resolve, 500)); // شبیه‌سازی تاخیر شبکه
    console.log("Deleting job:", jobToDelete.value.JobID);
    
    fetchJobs(); // بارگذاری مجدد لیست
  } catch (error) {
    console.error("Error deleting job:", error);
    // نمایش خطا به کاربر
  } finally {
    if (deleteConfirmationModalInstance) {
        deleteConfirmationModalInstance.hide();
    }
    jobToDelete.value = null;
  }
};

// توابع کمکی برای قالب‌بندی نمایش
const formatDate = (dateString) => {
  if (!dateString) return GetLocale('N/A');
  try {
    return new Date(dateString).toLocaleDateString(GetLocale('get-current-locale') || 'en-US', { year: 'numeric', month: 'short', day: 'numeric' });
  } catch (e) { return dateString; }
};

const formatField = (field) => {
  const map = { 'total_receive': GetLocale('Total Received'), 'total_sent': GetLocale('Total Sent'), 'total_data': GetLocale('Total Usage'), 'latest_handshake': GetLocale('Last Handshake') };
  return map[field] || field;
};

const formatOperator = (op) => {
  const map = { 'eq': '=', 'neq': '!=', 'lgt': '>', 'lst': '<' };
  return map[op] || op;
};

const formatAction = (action) => {
  const map = { 'restrict': GetLocale('Restrict'), 'delete': GetLocale('Delete') };
  return map[action] || action;
};

const getActionBadgeClass = (action) => {
  if (action === 'restrict') return 'bg-warning text-dark';
  if (action === 'delete') return 'bg-danger';
  return 'bg-secondary';
};

</script>

<style scoped>
.peer-jobs-list-container {
  background-color: #f8f9fa; /* رنگ پس‌زمینه روشن */
}
.table th {
    font-weight: 500;
}
.table samp {
    font-family: var(--bs-font-monospace);
    font-size: 0.9em;
}
.btn-outline-primary:hover i, .btn-outline-danger:hover i {
    color: white;
}
</style>
