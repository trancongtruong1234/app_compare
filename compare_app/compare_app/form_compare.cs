using System;
using System.IO;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using System.Diagnostics;

namespace compare_app
{
    public partial class form_compare : Form
    {
        public form_compare()
        {
            InitializeComponent();
        }

        private void chose_path(string cmd,string path)
        {
            FolderBrowserDialog file = new FolderBrowserDialog();
            if (file.ShowDialog() == System.Windows.Forms.DialogResult.OK)
            {
                string file_path = cmd +"" + (file.SelectedPath).Replace('\\', '/');
                StreamWriter sw = new StreamWriter(path);
                sw.WriteAsync(file_path);
                sw.Close();
                MessageBox.Show("Select success " + file.SelectedPath, 
                    "Congratulation",
                    MessageBoxButtons.OK, 
                    MessageBoxIcon.Information);
            }
        }
        private void compare(string path, string runcmd )
        {
            StreamWriter sw = new StreamWriter(path+"/run_round.bat");
            string text = "@echo off\n"
                + "call " + path + "\\source.bat\n"
                + "call " + path + "\\result.bat\n"
                + "cd " + path + "\\demo_dbt-master\n"
                + "call venv\\Scripts\\activate\n"
                + runcmd + "\n"
                + "pause";
            sw.WriteAsync(text);
            sw.Close();

            Process test = new Process();
            test.StartInfo.FileName =path + "/run_round.bat";
            test.StartInfo.UseShellExecute = false;
            test.StartInfo.Arguments = "/all";
            test.StartInfo.RedirectStandardOutput = true;
            test.Start();
            test.Close();
        }

        private void get_result_list()
        {
            listRound.Items.Clear();
            listRegion.Items.Clear();
            try
            {
                string result_round_paths = File.ReadAllText("Round/result.bat");
                string result_round_path = result_round_paths.Substring(16);
                textBox2.Text = result_round_path;

                string source_round_paths = File.ReadAllText("Round/source.bat");
                string source_round_path = source_round_paths.Substring(16);
                textBox1.Text = source_round_path;

                string result_coke_dms_mm_paths = File.ReadAllText("MM_DMS/result.bat");
                string result_coke_dms_mm_path = result_coke_dms_mm_paths.Substring(16);
                txtResultCokeDmsMm.Text = result_coke_dms_mm_path;

                string source_coke_dms_mm_paths = File.ReadAllText("MM_DMS/source.bat");
                string source_coke_dms_mm_path = source_coke_dms_mm_paths.Substring(16);
                txtSourceCokeDmsMm.Text = source_coke_dms_mm_path;

                string path__round = result_round_path;
                string[] round_name = Directory.GetDirectories(path__round, "*", SearchOption.TopDirectoryOnly);

                foreach (string name in round_name)
                {
                    listRound.Items.Add(name.Substring(name.Length - 14));
                }

                string path_coke_dms_mm = result_coke_dms_mm_path;
                string[] region_name = Directory.GetDirectories(path_coke_dms_mm, "*", SearchOption.TopDirectoryOnly);

                foreach (string name in region_name)
                {
                    listRegion.Items.Add(name.Substring(name.Length - 4));
                }
            }
            catch
            { }
        }
        private void btn_chose_source_Click(object sender, EventArgs e)
        {
            if (tabControl.SelectedTab.Text.ToString() == "KCC")
            {
                chose_path("set source_path=","Round/source.bat");
            }
            if (tabControl.SelectedTab.Text.ToString() == "COKE_DMS_MM")
            {
                chose_path("set source_path=","MM_DMS/source.bat");
            }
            get_result_list();
        }

        private void btn_chose_result_Click(object sender, EventArgs e)
        {
            if (tabControl.SelectedTab.Text.ToString() == "KCC")
            {
                chose_path("set result_path=","Round/result.bat");
            }
            if (tabControl.SelectedTab.Text.ToString() == "COKE_DMS_MM")
            {
                chose_path("set result_path=", "MM_DMS/result.bat");
            }
            get_result_list();
        }

        private void btn_compare_Click(object sender, EventArgs e)
        {
            if (tabControl.SelectedTab.Text.ToString() == "KCC")
            {
                String runcmd = "call start dbt run ";
                foreach (string itemchecked in listRound.CheckedItems)
                {
                    runcmd += "-s " + itemchecked + " ";
                }
                compare("Round",runcmd);
            }

            if (tabControl.SelectedTab.Text.ToString() == "COKE_DMS_MM")
            {
                String runcmd = "call start dbt run ";
                foreach (string itemchecked in listRegion.CheckedItems)
                {
                    runcmd += "--model compare." + itemchecked + " ";
                }
                compare("MM_DMS", runcmd);
            }

        }

        private void form_compare1_Load(object sender, EventArgs e)
        {
            get_result_list();
        }
    }
}
