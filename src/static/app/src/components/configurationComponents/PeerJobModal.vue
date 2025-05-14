<template>
  <div class="modal fade" id="peerJobModal" tabindex="-1" aria-labelledby="peerJobModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title" id="peerJobModalLabel">
            <i class="bi bi-calendar-plus me-2"></i>
            <LocaleText :t="editableJob && editableJob.JobID ? 'Edit Peer Job' : 'Add New Peer Job'"></LocaleText>
            <span v-if="peerName" class="text-muted small ms-2"> for {{ peerName }}</span>
          </h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body" v-if="editableJob">
          <form @submit.prevent="submitPeerJobForm">
            <div class="alert alert-info small" role="alert">
              <LocaleText t="Peer jobs allow you to automate actions based on peer data. For example, restrict a peer if total data usage exceeds a certain limit."></LocaleText>
            </div>

            <div class="row">
              <div class="col-md-6 mb-3">
                <label for="jobField" class="form-label"><LocaleText t="Field to Monitor"></LocaleText> <span class="text-danger">*</span></label>
                <select class="form-select" id="jobField" v-model="editableJob.Field" @change="updateValueInputType" required>
                  <option value="total_receive"><LocaleText t="Total Received Data (GB)"></LocaleText></option>
                  <option value="total_sent"><LocaleText t="Total Sent Data (GB)"></LocaleText></option>
                  <option value="total_data"><LocaleText t="Total Data Usage (GB)"></LocaleText></option>
                  <option value="latest_handshake"><LocaleText t="Latest Handshake (Time Ago)"></LocaleText></option>
                </select>
              </div>
              <div class="col-md-6 mb-3">
                <label for="jobOperator" class="form-label"><LocaleText t="Condition"></LocaleText> <span class="text-danger">*</span></label>
                <select class="form-select" id="jobOperator" v-model="editableJob.Operator" required>
                  <option value="eq"><LocaleText t="Equals (=)"></LocaleText></option>
                  <option value="neq"><LocaleText t="Not Equals (!=)"></LocaleText></option>
                  <option value="lgt"><LocaleText t="Greater Than (>)"></LocaleText></option>
                  <option value="lst"><LocaleText t="Less Than (<)"></LocaleText></option>
                </select>
              </div>
            </div>

            <div class="mb-3">
              <label for="jobValue" class="form-label"><LocaleText t="Value"></LocaleText> <span class="text-danger">*</span></label>
              <div v-if="editableJob.Field && editableJob.Field.includes('total_')">
                <div class="input-group">
                    <input type="number" class="form-control" id="jobValueNumber" v-model.number="editableJob.Value" required placeholder="e.g., 100" min="0" step="0.1">
                    <span class="input-group-text">GB</span>
                </div>
              </div>
              <div v-else-if="editableJob.Field === 'latest_handshake'">
                <!-- For 'latest_handshake', the value is typically a datetime string in the backend,
                     but for user input, it might be simpler to define "older than X days/hours/minutes"
                     or a specific date. For simplicity, let's assume the backend expects a specific format
                     or the logic is handled there. Here, we'll use a text input for a formatted string.
                     A more advanced UI would use a date picker or relative time input.
                -->
                <input type="text" class="form-control" id="jobValueDate" v-model="editableJob.Value" required :placeholder="GetLocale('e.g., 2023-12-31 23:59:59 or relative like 7 days')">
                <div class="form-text">
                    <LocaleText t="For handshake, enter a specific future date/time (YYYY-MM-DD HH:MM:SS) or a relative duration (e.g., '30 days ago' - backend logic dependent)."></LocaleText>
                </div>
              </div>
               <div v-else>
                 <input type="text" class="form-control" id="jobValueText" v-model="editableJob.Value" required :placeholder="GetLocale('Enter value')">
              </div>
            </div>

            <div class="mb-3">
              <label for="jobAction" class="form-label"><LocaleText t="Action to Perform"></LocaleText> <span class="text-danger">*</span></label>
              <select class="form-select" id="jobAction" v-model="editableJob.Action" required>
                <option value="restrict"><LocaleText t="Restrict Peer Access"></LocaleText></option>
                <option value="delete"><LocaleText t="Delete Peer"></LocaleText></option>
                <!-- Add other actions if available from backend -->
              </select>
            </div>
            
            <div v-if="editableJob.JobID" class="mb-3">
                <label class="form-label"><LocaleText t="Job ID"></LocaleText></label>
                <input type="text" class="form-control" :value="editableJob.JobID" disabled readonly>
            </div>
            <div v-if="editableJob.CreationDate" class="mb-3">
                <label class="form-label"><LocaleText t="Creation Date"></LocaleText></label>
                <input type="text" class="form-control" :value="formatDate(editableJob.CreationDate)" disabled readonly>
            </div>

          </form>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
            <i class="bi bi-x-circle me-1"></i><LocaleText t="Cancel"></LocaleText>
          </button>
          <button type="submit" class="btn btn-primary" @click="submitPeerJobForm" :disabled="isSubmitting">
            <span v-if="isSubmitting" class="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span>
            <i v-else class="bi bi-check-circle me-1"></i>
            <LocaleText :t="editableJob && editableJob.JobID ? 'Save Changes' : 'Create Job'"></LocaleText>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, watch, defineProps, defineEmits, toRefs } from 'vue';
import { GetLocale } from "@/utilities/locale.js"; // مسیر فرضی
import LocaleText from "@/components/text/localeText.vue"; // مسیر فرضی
import { v4 as uuidv4 } from 'uuid'; // برای تولید JobID جدید

const props = defineProps({
  jobToEdit: Object, // کار (job) که برای ویرایش پاس داده می‌شود
  configurationName: {
    type: String,
    required: true
  },
  peerId: {
    type: String,
    required: true
  },
  peerName: String // نام همتا برای نمایش در عنوان مدال
});

const emit = defineEmits(['jobSaved']);

const { jobToEdit, configurationName, peerId } = toRefs(props);

const editableJob = reactive({
  JobID: '',
  Configuration: configurationName.value,
  Peer: peerId.value,
  Field: 'total_data', // مقدار پیش‌فرض
  Operator: 'lgt',     // مقدار پیش‌فرض
  Value: '',
  Action: 'restrict',  // مقدار پیش‌فرض
  CreationDate: null,
  ExpireDate: null // معمولاً برای کارهای جدید null است
});

const isSubmitting = ref(false);

watch(jobToEdit, (newVal) => {
  if (newVal && Object.keys(newVal).length > 0) {
    Object.assign(editableJob, JSON.parse(JSON.stringify(newVal)));
    // اطمینان از اینکه Configuration و Peer از props گرفته شده‌اند اگر jobToEdit آنها را ندارد
    editableJob.Configuration = configurationName.value;
    editableJob.Peer = peerId.value;
  } else {
    // Reset to default for new job
    editableJob.JobID = ''; // یا uuidv4() اگر می‌خواهید در کلاینت تولید شود
    editableJob.Configuration = configurationName.value;
    editableJob.Peer = peerId.value;
    editableJob.Field = 'total_data';
    editableJob.Operator = 'lgt';
    editableJob.Value = '';
    editableJob.Action = 'restrict';
    editableJob.CreationDate = null;
    editableJob.ExpireDate = null;
  }
}, { immediate: true, deep: true });

// این تابع برای به‌روزرسانی نوع ورودی مقدار بر اساس فیلد انتخاب شده است (در اینجا ساده شده)
const updateValueInputType = () => {
  // در اینجا می‌توان منطقی برای تغییر نوع ورودی بر اساس editableJob.Field اضافه کرد
  // اما با توجه به ساختار فعلی template، این کار به طور خودکار با v-if انجام می‌شود.
  // فقط مقدار Value را ریست می‌کنیم تا کاربر مقدار جدیدی وارد کند.
  editableJob.Value = '';
};

const formatDate = (dateString) => {
  if (!dateString) return '';
  try {
    const options = { year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit' };
    return new Date(dateString).toLocaleDateString(GetLocale('get-current-locale') || 'en-US', options);
  } catch (e) {
    return dateString; // بازگرداندن رشته اصلی در صورت خطا
  }
};

const submitPeerJobForm = async () => {
  isSubmitting.value = true;
  
  // اعتبارسنجی اولیه (می‌تواند گسترش یابد)
  if (!editableJob.Field || !editableJob.Operator || editableJob.Value === '' || !editableJob.Action) {
    alert(GetLocale("Please fill all required fields.")); // از یک سیستم نوتیفیکیشن بهتر استفاده کنید
    isSubmitting.value = false;
    return;
  }

  const jobPayload = { ...editableJob };
  if (!jobPayload.JobID) {
    // jobPayload.JobID = uuidv4(); // اگر JobID باید در کلاینت تولید شود و در بک‌اند وجود ندارد
    // در غیر این صورت، بک‌اند باید JobID را تولید کند و فیلد CreationDate را نیز مدیریت کند.
    // برای سادگی، فرض می‌کنیم بک‌اند این موارد را مدیریت می‌کند اگر JobID خالی ارسال شود.
  }
  
  // TODO: ارسال jobPayload به API بک‌اند (مثلاً /api/savePeerScheduleJob)
  // از dashboard.py: AllPeerJobs.saveJob(PeerJob(...))
  console.log("Submitting Peer Job:", jobPayload);

  try {
    // شبیه‌سازی فراخوانی API
    // const response = await fetch(`/api/savePeerScheduleJob`, {
    //   method: 'POST',
    //   headers: { 'Content-Type': 'application/json' },
    //   body: JSON.stringify({ Job: jobPayload })
    // });
    // const result = await response.json();
    // if (!result.status) throw new Error(result.message || 'Failed to save job');
    
    await new Promise(resolve => setTimeout(resolve, 1000)); // شبیه‌سازی تاخیر شبکه
    
    emit('jobSaved', jobPayload); // ارسال رویداد به کامپوننت والد
    alert(GetLocale("Peer job saved successfully!")); // از یک سیستم نوتیفیکیشن بهتر استفاده کنید
    
    // بستن مدال (نیاز به دسترسی به نمونه مدال Bootstrap دارد)
    // const modalElement = document.getElementById('peerJobModal');
    // if (modalElement) {
    //   const modalInstance = bootstrap.Modal.getInstance(modalElement);
    //   if (modalInstance) modalInstance.hide();
    // }
  } catch (error) {
    console.error("Error saving peer job:", error);
    alert(GetLocale("Error saving peer job: ") + error.message); // از یک سیستم نوتیفیکیشن بهتر استفاده کنید
  } finally {
    isSubmitting.value = false;
  }
};

</script>

<style scoped>
/* Styles specific to this modal can go here */
.form-text {
  font-size: 0.875em;
}
.modal-footer .btn {
    min-width: 120px;
}
input[readonly] {
  background-color: #e9ecef;
  cursor: not-allowed;
}
</style>
